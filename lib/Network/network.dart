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
  
  bool _isLocalMode = false;
  Timer? _localPollTimer;
  StreamSubscription? _fbSensorSub;
  StreamSubscription? _fbRelaySub;
  StreamSubscription? _fbDevicesSub;

  List<Map<String, dynamic>> _cachedDevices = [];

  static final List<Map<String, dynamic>> _defaultDevices = [
    {
      "id": "device_lights",
      "name": "Main Lights",
      "room": "Living Room",
      "isWired": true,
      "port": 2, // Built-in LED pin
      "state": false,
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
      "state": true,
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
      "state": false,
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
      "state": false,
      "icon": "air",
      "glowColor": "orange",
      "status": "faulty"
    }
  ];

  NetworkService() {
    _probeConnectivity();
    // Regularly probe network state every 15 seconds to handle subnet transitions
    Timer.periodic(const Duration(seconds: 15), (_) => _probeConnectivity());
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
        }
      }
    } catch (_) {
      if (_isLocalMode) {
        _isLocalMode = false;
        _enableCloudMode();
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
    
    // Begin direct polling over local network
    _localPollTimer?.cancel();
    _localPollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollLocalTelemetry());
    _pollLocalTelemetry(); // Trigger initial payload fetch

    // Broadcast whatever we have in the local devices cache
    if (_cachedDevices.isEmpty) {
      _cachedDevices = List.from(_defaultDevices);
    }
    _devicesController.add(_cachedDevices);
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
              devices.add({
                "id": key.toString(),
                "name": val["name"] ?? "",
                "room": val["room"] ?? "",
                "isWired": val["isWired"] ?? false,
                "port": val["port"],
                "state": val["state"] ?? false,
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
    // 1. Optimistically update local cache list and broadcast immediately to UI
    final index = _cachedDevices.indexWhere((d) => d["id"] == id);
    if (index != -1) {
      _cachedDevices[index]["state"] = value;
      _devicesController.add(List.from(_cachedDevices));
      
      final device = _cachedDevices[index];
      final bool isWired = device["isWired"] ?? false;
      final int? port = device["port"];

      // 2. Perform local network direct REST action or cloud Firebase sync
      if (_isLocalMode) {
        if (isWired && port != null) {
          try {
            final stateParam = value ? "1" : "0";
            await http.get(Uri.parse("$localBaseUrl/api/device?port=$port&state=$stateParam")).timeout(const Duration(seconds: 2));
          } catch (_) {
            // Local fallback failed, send to database
            await _databaseRef.child("${_userBasePath}home/devices/$id/state").set(value);
          }
        }
      } else {
        await _databaseRef.child("${_userBasePath}home/devices/$id/state").set(value);
        // Also keep legacy cloud light sync updated if it's the main light bulb
        if (id == "device_lights") {
          await _databaseRef.child("${_userBasePath}home/light/").set(value);
        }
      }
    }
  }

  /// Dynamically registers a new custom device into the system
  Future<void> addDevice(Map<String, dynamic> device) async {
    final String id = device["id"] ?? "device_${DateTime.now().millisecondsSinceEpoch}";
    final Map<String, dynamic> fullDevice = {
      "id": id,
      "name": device["name"] ?? "Unnamed Device",
      "room": device["room"] ?? "Living Room",
      "isWired": device["isWired"] ?? false,
      "port": device["port"],
      "state": device["state"] ?? false,
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

  void dispose() {
    _localPollTimer?.cancel();
    _fbSensorSub?.cancel();
    _fbRelaySub?.cancel();
    _fbDevicesSub?.cancel();
    _sensorController.close();
    _relayController.close();
    _devicesController.close();
  }
}
