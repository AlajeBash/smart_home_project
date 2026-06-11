import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NetworkService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  
  /// Dynamically computes the base path for the authenticated user, or empty for legacy/fallback.
  String get _userBasePath {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return (uid != null && uid.isNotEmpty) ? "users/$uid/" : "";
  }
  
  // Local network configuration gateway (mDNS resolving)
  static const String localBaseUrl = "http://aminai-hub.local";
  
  // Broadcast stream controllers to unify local subnet and global cloud feeds
  final _sensorController = StreamController<Map<String, dynamic>>.broadcast();
  final _relayController = StreamController<bool>.broadcast();
  final _devicesController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _diagnosticsController = StreamController<Map<String, dynamic>>.broadcast();
  
  bool _isLocalMode = false;
  Timer? _localPollTimer;
  StreamSubscription? _fbSensorSub;
  StreamSubscription? _fbRelaySub;
  StreamSubscription? _fbDevicesSub;
  StreamSubscription? _fbDiagnosticsSub;

  List<Map<String, dynamic>> _cachedDevices = [];
  Map<String, dynamic>? _lastDiagnosticsData;

  static final List<Map<String, dynamic>> _defaultDevices = [
    {
      "id": "device_lights",
      "name": "Main Lights",
      "room": "Living Room",
      "isWired": true,
      "port": 2, // Built-in LED pin
      "direction": "output",
      "valueType": "binary",
      "pinMode": "default",
      "state": false,
      "value": false,
      "icon": "lightbulb",
      "glowColor": "amber",
      "status": "online"
    },
    {
      "id": "device_purifier",
      "name": "Air Purifier",
      "room": "Bedroom",
      "isWired": false,
      "port": null,
      "direction": "output",
      "valueType": "binary",
      "pinMode": "default",
      "state": true,
      "value": true,
      "icon": "air",
      "glowColor": "teal",
      "status": "online"
    },
    {
      "id": "device_camera",
      "name": "Foyer Camera",
      "room": "Entrance",
      "isWired": false,
      "port": null,
      "direction": "both",
      "valueType": "binary",
      "pinMode": "default",
      "state": false,
      "value": false,
      "icon": "videocam",
      "glowColor": "blue",
      "status": "offline"
    },
    {
      "id": "device_humidifier",
      "name": "Smart Humidifier",
      "room": "Kitchen",
      "isWired": true,
      "port": 15,
      "direction": "output",
      "valueType": "dimmer",
      "pinMode": "default",
      "state": false,
      "value": 45,
      "icon": "air",
      "glowColor": "orange",
      "status": "online"
    }
  ];

  NetworkService() {
    _probeConnectivity();
    // Regularly probe network state every 15 seconds to handle subnet transitions
    Timer.periodic(const Duration(seconds: 15), (_) => _probeConnectivity());

    // Listen to authentication changes and trigger profile initialization
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _initializeUserProfile(user);
      }
    });
  }

  /// Check if local subnet mode is active
  bool get isLocalMode => _isLocalMode;

  /// Performs a quick HTTP request to test if the local ESP32 API is reachable
  Future<void> _probeConnectivity() async {
    try {
      final response = await http.get(Uri.parse("$localBaseUrl/api/sensors")).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        if (!_isLocalMode) {
          _isLocalMode = true;
          _enableLocalMode();
        }
      } else {
        if (_isLocalMode) {
          _isLocalMode = false;
          _enableCloudMode();
        } else {
          _emitDiagnostics();
        }
      }
    } catch (_) {
      if (_isLocalMode) {
        _isLocalMode = false;
        _enableCloudMode();
      } else {
        _emitDiagnostics();
      }
    }
  }

  /// Configures local polling direct from the ESP32 node
  void _enableLocalMode() {
    print("AMINAI Connectivity Node: Offline Local Mode Engaged (Direct Subnet Communication)");
    
    // Suspend Firebase cloud subscriptions to conserve cell/data plans
    _fbSensorSub?.cancel();
    _fbRelaySub?.cancel();
    _fbDevicesSub?.cancel();
    _fbDiagnosticsSub?.cancel();
    
    // Begin direct polling over local network
    _localPollTimer?.cancel();
    _localPollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollLocalTelemetry());
    _pollLocalTelemetry(); // Trigger initial payload fetch

    // Broadcast whatever we have in the local devices cache
    if (_cachedDevices.isEmpty) {
      _cachedDevices = List.from(_defaultDevices);
    }
    _devicesController.add(_cachedDevices);

    _diagnosticsController.add({
      "online": true,
      "ip": "aminai-hub.local",
      "rssi": -35,
      "free_heap": 218450,
      "uptime": "Direct (LAN)",
    });
  }

  /// Configures remote synchronization from Firebase Realtime Database
  void _enableCloudMode() {
    print("AMINAI Connectivity Node: Global Cloud Mode Engaged (Firebase Sync Active)");
    
    // Disable local polling
    _localPollTimer?.cancel();
    
    // Setup Firebase database stream subscriptions
    _fbSensorSub?.cancel();
    _fbSensorSub = _databaseRef.child("${_userBasePath}sensors").onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      _sensorController.add({
        "temperature": data?["temperature"] != null ? (data!["temperature"] as num).toDouble() : 24.5,
        "humidity": data?["humidity"] != null ? (data!["humidity"] as num).toDouble() : 48.0,
      });
    });

    _fbRelaySub?.cancel();
    _fbRelaySub = _databaseRef.child("${_userBasePath}home/light/").onValue.listen((event) {
      final state = event.snapshot.value as bool?;
      _relayController.add(state ?? false);
    });

    _fbDevicesSub?.cancel();
    _fbDevicesSub = _databaseRef.child("${_userBasePath}home/devices").onValue.listen((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) {
        // If empty, initialize the database with standard default preloads
        _initializeDefaultDevices();
      } else {
        final Map? data = snapshot.value as Map?;
        if (data != null) {
          final List<Map<String, dynamic>> devices = [];
          data.forEach((key, val) {
            if (val is Map) {
              final String valType = val["valueType"] ?? "binary";
              final dynamic rawValue = val["value"] ?? val["state"] ?? (valType == "dimmer" ? 0 : false);
              devices.add({
                "id": key.toString(),
                "name": val["name"] ?? "",
                "room": val["room"] ?? "",
                "isWired": val["isWired"] ?? false,
                "port": val["port"],
                "direction": val["direction"] ?? "output",
                "valueType": valType,
                "pinMode": val["pinMode"] ?? "default",
                "state": val["state"] ?? (rawValue is bool ? rawValue : (rawValue is num && rawValue > 0)),
                "value": rawValue,
                "icon": val["icon"] ?? "lightbulb",
                "glowColor": val["glowColor"] ?? "amber",
                "status": val["status"] ?? "online",
              });
            }
          });
          _cachedDevices = devices;
          _devicesController.add(_cachedDevices);
        }
      }
    });

    _fbDiagnosticsSub?.cancel();
    _fbDiagnosticsSub = _databaseRef.child("${_userBasePath}diagnostics").onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value is Map) {
        final Map data = snapshot.value as Map;
        _lastDiagnosticsData = {
          "online": data["online"] ?? false,
          "ip": data["ip"] ?? "0.0.0.0",
          "rssi": data["rssi"] ?? -100,
          "free_heap": data["free_heap"] ?? 0,
          "uptime": data["uptime"] ?? "Offline",
          "last_seen": data["last_seen"] ?? 0,
        };
        _emitDiagnostics();
      } else {
        _lastDiagnosticsData = null;
        _diagnosticsController.add({
          "online": false,
          "ip": "0.0.0.0",
          "rssi": -100,
          "free_heap": 0,
          "uptime": "Offline",
        });
      }
    });
  }

  /// Calculates and broadcasts active heartbeat presence status to listeners
  void _emitDiagnostics() {
    if (_isLocalMode) return; // Direct LAN mode uses its own emitted static diagnostics
    
    if (_lastDiagnosticsData == null) {
      _diagnosticsController.add({
        "online": false,
        "ip": "0.0.0.0",
        "rssi": -100,
        "free_heap": 0,
        "uptime": "Offline",
      });
      return;
    }
    
    final int lastSeen = _lastDiagnosticsData!["last_seen"] ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;
    
    // Mark as online if last seen heartbeat is within the 45-second tolerance window
    final bool isOnline = lastSeen > 0 && (now - lastSeen < 45000);
    
    _diagnosticsController.add({
      "online": isOnline,
      "ip": isOnline ? (_lastDiagnosticsData!["ip"] ?? "0.0.0.0") : "0.0.0.0",
      "rssi": isOnline ? (_lastDiagnosticsData!["rssi"] ?? -100) : -100,
      "free_heap": isOnline ? (_lastDiagnosticsData!["free_heap"] ?? 0) : 0,
      "uptime": isOnline ? (_lastDiagnosticsData!["uptime"] ?? "Offline") : "Offline",
    });
  }

  /// Initializes standard default devices in the database
  Future<void> _initializeDefaultDevices() async {
    for (var device in _defaultDevices) {
      await _databaseRef.child("${_userBasePath}home/devices/${device['id']}").set(device);
    }
  }

  /// Polls the ESP32 local HTTP REST API for real-time sensor telemetry
  Future<void> _pollLocalTelemetry() async {
    if (!_isLocalMode) return;
    try {
      final response = await http.get(Uri.parse("$localBaseUrl/api/sensors")).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _sensorController.add({
          "temperature": (data["temperature"] as num).toDouble(),
          "humidity": (data["humidity"] as num).toDouble(),
        });
      }
    } catch (_) {
      _probeConnectivity(); // Local call failed, re-probe subnet link
    }
  }

  /// Listens to real-time climate telemetry sensor data
  Stream<Map<String, dynamic>> listenToSensorData() {
    if (_fbSensorSub == null && _localPollTimer == null) {
      _probeConnectivity();
    }
    return _sensorController.stream;
  }

  /// Listens to real-time light relay state changes
  Stream<bool> listenToRelayState() {
    if (_fbRelaySub == null && _localPollTimer == null) {
      _probeConnectivity();
    }
    return _relayController.stream;
  }

  /// Listens to the dynamic custom devices list stream
  Stream<List<Map<String, dynamic>>> listenToDevices() {
    if (_fbDevicesSub == null && _localPollTimer == null) {
      _probeConnectivity();
    }
    return _devicesController.stream;
  }

  /// Listens to the real-time ESP32 hardware diagnostics stream
  Stream<Map<String, dynamic>> listenToDiagnostics() {
    if (_fbDiagnosticsSub == null && _localPollTimer == null) {
      _probeConnectivity();
    }
    return _diagnosticsController.stream;
  }

  /// Toggles the light relay switch state locally or globally (legacy fallback)
  Future<void> toggleRelayState(bool value) async {
    if (_isLocalMode) {
      try {
        final stateParam = value ? "1" : "0";
        final response = await http.get(Uri.parse("$localBaseUrl/api/light?state=$stateParam")).timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          _relayController.add(value); // Optimistically broadcast local state updates
        }
      } catch (_) {
        await _databaseRef.child("${_userBasePath}home/light/").set(value);
      }
    } else {
      await _databaseRef.child("${_userBasePath}home/light/").set(value);
    }
  }

  /// Toggles a specific dynamic device's state locally or globally
  Future<void> toggleDeviceState(String id, bool value) async {
    await updateDeviceValue(id, value);
  }

  /// Updates a specific device's general value (boolean toggle or numerical dim/sensor representation)
  Future<void> updateDeviceValue(String id, dynamic value) async {
    // 1. Optimistically update local cache list and broadcast immediately to UI
    final index = _cachedDevices.indexWhere((d) => d["id"] == id);
    if (index != -1) {
      _cachedDevices[index]["value"] = value;
      if (value is bool) {
        _cachedDevices[index]["state"] = value;
      } else if (value is num) {
        _cachedDevices[index]["state"] = value > 0;
      }
      _devicesController.add(List.from(_cachedDevices));
      
      final device = _cachedDevices[index];
      final bool isWired = device["isWired"] ?? false;
      final int? port = device["port"];

      // 2. Perform local network direct REST action or cloud Firebase sync
      if (_isLocalMode) {
        if (isWired && port != null) {
          try {
            final valueStr = value.toString();
            await http.get(Uri.parse("$localBaseUrl/api/device?port=$port&value=$valueStr")).timeout(const Duration(seconds: 2));
          } catch (_) {
            // Local fallback failed, send to database
            await _databaseRef.child("${_userBasePath}home/devices/$id/value").set(value);
            if (value is bool) {
              await _databaseRef.child("${_userBasePath}home/devices/$id/state").set(value);
            }
          }
        }
      } else {
        await _databaseRef.child("${_userBasePath}home/devices/$id/value").set(value);
        if (value is bool) {
          await _databaseRef.child("${_userBasePath}home/devices/$id/state").set(value);
        }
        // Also keep legacy cloud light sync updated if it's the main light bulb
        if (id == "device_lights") {
          await _databaseRef.child("${_userBasePath}home/light/").set(value is bool ? value : (value as num) > 0);
        }
      }
    }
  }

  /// Commands the ESP32 microcontroller to execute a remote soft reboot
  Future<void> rebootController() async {
    if (_isLocalMode) {
      try {
        await http.get(Uri.parse("$localBaseUrl/api/reboot")).timeout(const Duration(seconds: 2));
      } catch (_) {
        await _databaseRef.child("${_userBasePath}diagnostics/reboot").set(true);
      }
    } else {
      await _databaseRef.child("${_userBasePath}diagnostics/reboot").set(true);
    }
  }

  /// Dynamically registers a new custom device into the system
  Future<void> addDevice(Map<String, dynamic> device) async {
    final String id = device["id"] ?? "device_${DateTime.now().millisecondsSinceEpoch}";
    final valType = device["valueType"] ?? "binary";
    final dynamic initVal = device["value"] ?? (valType == "dimmer" ? 0 : false);
    
    final Map<String, dynamic> fullDevice = {
      "id": id,
      "name": device["name"] ?? "Unnamed Device",
      "room": device["room"] ?? "Living Room",
      "isWired": device["isWired"] ?? false,
      "port": device["port"],
      "direction": device["direction"] ?? "output",
      "valueType": valType,
      "pinMode": device["pinMode"] ?? "default",
      "state": device["state"] ?? (initVal is bool ? initVal : (initVal is num && initVal > 0)),
      "value": initVal,
      "icon": device["icon"] ?? "lightbulb",
      "glowColor": device["glowColor"] ?? "amber",
      "status": device["status"] ?? "online",
    };

    if (_isLocalMode) {
      // Offline local mode cache adding
      _cachedDevices.add(fullDevice);
      _devicesController.add(List.from(_cachedDevices));
    } else {
      // Cloud database adding
      await _databaseRef.child("${_userBasePath}home/devices/$id").set(fullDevice);
    }
  }

  /// Updates a device's room location
  Future<void> updateDeviceRoom(String id, String newRoom) async {
    final index = _cachedDevices.indexWhere((d) => d["id"] == id);
    if (index != -1) {
      _cachedDevices[index]["room"] = newRoom;
      _devicesController.add(List.from(_cachedDevices));
    }
    if (!_isLocalMode) {
      await _databaseRef.child("${_userBasePath}home/devices/$id/room").set(newRoom);
    }
  }

  /// Removes a custom device dynamically
  Future<void> deleteDevice(String id) async {
    if (_isLocalMode) {
      _cachedDevices.removeWhere((d) => d["id"] == id);
      _devicesController.add(List.from(_cachedDevices));
    } else {
      await _databaseRef.child("${_userBasePath}home/devices/$id").remove();
    }
  }

  /// Initializes the user's profile under /users/<uid>/profile if empty.
  /// Automatically bootstrap 'admin' role if the email is 'admin@aminai.com'.
  Future<void> _initializeUserProfile(User user) async {
    final uid = user.uid;
    final email = user.email ?? "";
    final displayName = user.displayName ?? (email.isNotEmpty ? email.split('@').first : "Anonymous");

    final profileRef = _databaseRef.child("users/$uid/profile");
    try {
      final snapshot = await profileRef.get();
      String role = "user";
      if (email.toLowerCase() == "admin@aminai.com") {
        role = "admin";
      }

      if (!snapshot.exists) {
        await profileRef.set({
          "email": email,
          "role": role,
          "displayName": displayName,
          "createdAt": ServerValue.timestamp,
          "device_uid": "", // Initialized empty for device linking handshake
        });
        print("AMINAI Admin System: Initialized profile for $email with role $role");
        logEvent("New user account registered: $email", "auth");
      } else {
        final Map? data = snapshot.value as Map?;
        final currentRole = data?["role"] ?? "user";
        if (email.toLowerCase() == "admin@aminai.com" && currentRole != "admin") {
          await profileRef.child("role").set("admin");
          print("AMINAI Admin System: Auto-upgraded $email to admin");
          logEvent("User auto-upgraded to admin: $email", "auth");
        }
      }
    } catch (e) {
      print("Error initializing user profile in Firebase: $e");
    }
  }

  /// Listens to the current user's role in real-time
  Stream<String> listenToUserRole() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return Stream.value("user");
    }
    return _databaseRef.child("users/$uid/profile/role").onValue.map((event) {
      final role = event.snapshot.value as String?;
      return role ?? "user";
    });
  }

  /// Listens to all user profiles (Admin utility)
  Stream<List<Map<String, dynamic>>> listenToAllUsers() {
    return _databaseRef.child("users").onValue.map((event) {
      final List<Map<String, dynamic>> users = [];
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value is Map) {
        final Map data = snapshot.value as Map;
        data.forEach((key, value) {
          if (value is Map && value.containsKey("profile")) {
            final profile = value["profile"] as Map;
            users.add({
              "uid": key.toString(),
              "email": profile["email"] ?? "",
              "role": profile["role"] ?? "user",
              "displayName": profile["displayName"] ?? "",
              "createdAt": profile["createdAt"] ?? 0,
              "device_uid": profile["device_uid"] ?? "",
            });
          }
        });
      }
      return users;
    });
  }

  /// Updates a user's role (Admin utility)
  Future<void> updateUserRole(String targetUid, String newRole) async {
    await _databaseRef.child("users/$targetUid/profile/role").set(newRole);
    logEvent("User role updated for UID $targetUid to $newRole", "admin");
  }

  /// Listens to all registered devices across all users (Admin utility)
  Stream<List<Map<String, dynamic>>> listenToGlobalDevices() {
    return _databaseRef.child("users").onValue.map((event) {
      final List<Map<String, dynamic>> globalDevices = [];
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value is Map) {
        final Map usersData = snapshot.value as Map;
        usersData.forEach((userKey, userValue) {
          if (userValue is Map && userValue.containsKey("home") && userValue["home"] is Map) {
            final home = userValue["home"] as Map;
            if (home.containsKey("devices") && home["devices"] is Map) {
              final devices = home["devices"] as Map;
              final profile = userValue["profile"] as Map?;
              final userEmail = profile?["email"] ?? "Unknown User";

              devices.forEach((deviceKey, deviceValue) {
                if (deviceValue is Map) {
                  final String valType = deviceValue["valueType"] ?? "binary";
                  final dynamic rawValue = deviceValue["value"] ?? deviceValue["state"] ?? (valType == "dimmer" ? 0 : false);
                  globalDevices.add({
                    "id": deviceKey.toString(),
                    "userUid": userKey.toString(),
                    "userEmail": userEmail,
                    "name": deviceValue["name"] ?? "",
                    "room": deviceValue["room"] ?? "",
                    "isWired": deviceValue["isWired"] ?? false,
                    "port": deviceValue["port"],
                    "direction": deviceValue["direction"] ?? "output",
                    "valueType": valType,
                    "pinMode": deviceValue["pinMode"] ?? "default",
                    "state": deviceValue["state"] ?? (rawValue is bool ? rawValue : (rawValue is num && rawValue > 0)),
                    "value": rawValue,
                    "icon": deviceValue["icon"] ?? "lightbulb",
                    "glowColor": deviceValue["glowColor"] ?? "amber",
                    "status": deviceValue["status"] ?? "online",
                  });
                }
              });
            }
          }
        });
      }
      return globalDevices;
    });
  }

  /// Listens to diagnostics telemetry for a specific user (Admin utility)
  Stream<Map<String, dynamic>> listenToUserDiagnostics(String targetUid) {
    return _databaseRef.child("users/$targetUid/diagnostics").onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value is Map) {
        final Map data = snapshot.value as Map;
        final int lastSeen = data["last_seen"] ?? 0;
        final int now = DateTime.now().millisecondsSinceEpoch;
        final bool isOnline = lastSeen > 0 && (now - lastSeen < 45000);
        return {
          "online": isOnline,
          "ip": isOnline ? (data["ip"] ?? "0.0.0.0") : "0.0.0.0",
          "rssi": isOnline ? (data["rssi"] ?? -100) : -100,
          "free_heap": isOnline ? (data["free_heap"] ?? 0) : 0,
          "uptime": isOnline ? (data["uptime"] ?? "Offline") : "Offline",
        };
      }
      return {
        "online": false,
        "ip": "0.0.0.0",
        "rssi": -100,
        "free_heap": 0,
        "uptime": "Offline",
      };
    });
  }

  /// Commands a specific user's ESP32 microcontroller to execute a soft reboot (Admin utility)
  Future<void> rebootUserController(String targetUid) async {
    await _databaseRef.child("users/$targetUid/diagnostics/reboot").set(true);
    logEvent("Triggered remote reboot for controller of UID $targetUid", "admin");
  }

  /// Listens to global system-wide activity logs (Admin utility)
  Stream<List<Map<String, dynamic>>> listenToGlobalLogs() {
    return _databaseRef.child("logs").limitToLast(100).onValue.map((event) {
      final List<Map<String, dynamic>> logs = [];
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value is Map) {
        final Map data = snapshot.value as Map;
        final sortedKeys = data.keys.toList()..sort();
        for (var key in sortedKeys.reversed) {
          final val = data[key];
          if (val is Map) {
            logs.add({
              "id": key.toString(),
              "message": val["message"] ?? "",
              "type": val["type"] ?? "general",
              "timestamp": val["timestamp"] ?? 0,
            });
          }
        }
      }
      return logs;
    });
  }

  /// Logs a system event to the global administrative logger
  Future<void> logEvent(String message, String type) async {
    final logRef = _databaseRef.child("logs").push();
    await logRef.set({
      "message": message,
      "type": type,
      "timestamp": ServerValue.timestamp,
    });
  }


  void dispose() {
    _localPollTimer?.cancel();
    _fbSensorSub?.cancel();
    _fbRelaySub?.cancel();
    _fbDevicesSub?.cancel();
    _fbDiagnosticsSub?.cancel();
    _sensorController.close();
    _relayController.close();
    _devicesController.close();
    _diagnosticsController.close();
  }
}
