import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_home_front_end/exports.dart';

class MobileBody extends StatefulWidget {
  const MobileBody({super.key});

  @override
  State<MobileBody> createState() => _MobileBodyState();
}

class _MobileBodyState extends State<MobileBody> {
  final NetworkService _networkService = NetworkService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double? temperature;
  double? humidity;
  bool relayState = false;

  // Mock devices states
  bool acState = false;
  double acTargetTemp = 24.0;
  bool purifierState = true;
  bool securityArm = true;
  bool blindsState = false;

  // Active room filter
  String activeRoom = "All Rooms";

  // Dynamic registered devices list
  List<Map<String, dynamic>> dynamicDevices = [];
  StreamSubscription? _devicesSub;

  // Navigation state
  String selectedSection = "Dashboard";

  // Dynamic user rooms list
  List<String> userRooms = ["Living Room", "Bedroom", "Kitchen", "Smart Office"];

  // Security keypad state
  String enteredPin = "";
  String activeCamera = "Front Porch";

  // Custom automation rules
  List<Map<String, String>> customRules = [
    {"trigger": "If Temperature > 28°C", "action": "Turn ON Air Purifier", "enabled": "true"},
    {"trigger": "If Sunset", "action": "Turn ON Main Lights", "enabled": "true"},
  ];

  // Event Logger State
  List<String> systemLogs = [
    "[12:45:10] Firebase RTDB: Connected to Cloud Server Stream",
    "[12:30:00] ESP32 Hub: State synchronized with Flash NVS",
  ];

  bool isCheckingOTA = false;
  double uiContrast = 1.0;
  String mdnsHost = "aura-hub.local";

  void _logEvent(String message) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    if (mounted) {
      setState(() {
        systemLogs.insert(0, "[$timeStr] $message");
        if (systemLogs.length > 50) {
          systemLogs.removeLast();
        }
      });
    }
  }

  // Real-time chart history lists
  final List<double> tempHistory = [22.4, 22.8, 23.1, 23.5, 23.8, 24.2, 24.5, 24.3, 24.0, 23.8, 24.1, 24.4];
  final List<double> humHistory = [45.0, 46.2, 47.1, 48.5, 49.0, 50.2, 51.5, 52.0, 51.1, 49.5, 48.0, 48.8];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _devicesSub = _networkService.listenToDevices().listen((devicesList) {
      if (mounted) {
        setState(() {
          dynamicDevices = devicesList;
          // Synchronize relayState with device_lights state
          final lightDevice = devicesList.firstWhere((d) => d["id"] == "device_lights", orElse: () => {});
          if (lightDevice.isNotEmpty) {
            relayState = lightDevice["state"] ?? false;
          }
        });
      }
    });

    _networkService.listenToSensorData().listen((data) {
      if (mounted) {
        setState(() {
          temperature = data["temperature"];
          humidity = data["humidity"];
          
          if (temperature != null && temperature! > 0) {
            tempHistory.removeAt(0);
            tempHistory.add(temperature!);
          }
          if (humidity != null && humidity! > 0) {
            humHistory.removeAt(0);
            humHistory.add(humidity!);
          }
        });
      }
    });

    _networkService.listenToRelayState().listen((state) {
      if (mounted) {
        setState(() {
          relayState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    super.dispose();
  }

  void _toggleRelayState(bool value) {
    _networkService.toggleRelayState(value);
  }

  void _triggerScene(String scene) {
    setState(() {
      if (scene == "Away") {
        relayState = false;
        acState = false;
        purifierState = false;
        securityArm = true;
        _toggleRelayState(false);
      } else if (scene == "Movie") {
        relayState = true;
        acState = true;
        acTargetTemp = 21.0;
        blindsState = true;
        _toggleRelayState(true);
      } else if (scene == "Sleep") {
        relayState = false;
        acState = true;
        acTargetTemp = 23.0;
        blindsState = true;
        _toggleRelayState(false);
      } else if (scene == "Eco") {
        acState = false;
        purifierState = true;
        blindsState = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Scene '$scene' activated successfully."),
        backgroundColor: Colors.indigo.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==================== SECTION ROUTER ====================
  Widget _buildMainContent(double curTemp, double curHum) {
    switch (selectedSection) {
      case "Dashboard":
        return _buildDashboardView(curTemp, curHum);
      case "Rooms":
        return _buildRoomsView();
      case "Automations":
        return _buildAutomationsView();
      case "Security Panel":
        return _buildSecurityView();
      case "Analytics":
        return _buildAnalyticsView(curTemp, curHum);
      case "Settings":
        return _buildSettingsView();
      default:
        return _buildDashboardView(curTemp, curHum);
    }
  }

  // ==================== DASHBOARD VIEW ====================
  Widget _buildDashboardView(double curTemp, double curHum) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Greeting
          const Text(
            "Welcome Home, Bash",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),

          // Room chips horizontal scroll
          _buildRoomFilters(),
          const SizedBox(height: 18),

          // Climate Gauges Horizontal Slider / Stack
          const Text(
            "LIVE TELEMETRY NODES",
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  glowColor: const Color(0xFFE57373),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    children: [
                      const Text("Temp", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                      TemperatureGauge(temperature: curTemp),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassContainer(
                  glowColor: const Color(0xFF64B5F6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    children: [
                      const Text("Humidity", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                      HumidityGauge(humidity: curHum),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Trends Chart (Horizontal scroll / compact view)
          GlassContainer(
            height: 160,
            child: ClimateTrendsChart(
              dataPoints: tempHistory,
              lineColor: const Color(0xFFE57373),
              label: "LIVE TEMP TELEMETRY (24H)",
              suffix: "°C",
            ),
          ),
          const SizedBox(height: 18),

          // Automated scenes shortcuts
          const Text(
            "QUICK SCENE TRIGGER",
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSceneChip("Away", Icons.exit_to_app_rounded, "Away"),
                _buildSceneChip("Movie", Icons.movie_filter_rounded, "Movie"),
                _buildSceneChip("Sleep", Icons.bedtime_rounded, "Sleep"),
                _buildSceneChip("Eco", Icons.eco_rounded, "Eco"),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Devices Grid (2 columns on mobile)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CONNECTED DEVICES",
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF8E99F3), size: 20),
                onPressed: _showAddDeviceDialog,
                tooltip: "Register New Hardware Device",
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.8,
            ),
            itemCount: (activeRoom == "All Rooms" || activeRoom == "Bedroom" ? 1 : 0) +
                dynamicDevices.where((d) => activeRoom == "All Rooms" || d["room"] == activeRoom).length,
            itemBuilder: (context, index) {
              final filteredDevices = activeRoom == "All Rooms"
                  ? dynamicDevices
                  : dynamicDevices.where((d) => d["room"] == activeRoom).toList();

              final bool showAC = activeRoom == "All Rooms" || activeRoom == "Bedroom";
              if (showAC && index == 1) {
                return _buildACCard();
              }

              int deviceIndex = index;
              if (showAC && index > 1) {
                deviceIndex = index - 1;
              }

              if (deviceIndex >= filteredDevices.length || deviceIndex < 0) {
                return const SizedBox.shrink();
              }

              final device = filteredDevices[deviceIndex];
              final String id = device["id"] ?? "";
              final String name = device["name"] ?? "";
              final String room = device["room"] ?? "";
              final bool isWired = device["isWired"] ?? false;
              final int? port = device["port"];
              final bool state = device["state"] ?? false;
              final String iconStr = device["icon"] ?? "lightbulb";
              final String glowColorStr = device["glowColor"] ?? "amber";

              IconData deviceIcon;
              switch (iconStr) {
                case 'lightbulb': deviceIcon = Icons.lightbulb_outline_rounded; break;
                case 'air': deviceIcon = Icons.air_rounded; break;
                case 'videocam': deviceIcon = Icons.videocam_rounded; break;
                case 'fan': deviceIcon = Icons.toys_rounded; break;
                case 'outlet': deviceIcon = Icons.power_rounded; break;
                case 'tv': deviceIcon = Icons.tv_rounded; break;
                default: deviceIcon = Icons.device_unknown_rounded;
              }

              Color glowColor;
              switch (glowColorStr) {
                case 'amber': glowColor = Colors.amber; break;
                case 'teal': glowColor = Colors.tealAccent; break;
                case 'blue': glowColor = Colors.blueAccent; break;
                case 'purple': glowColor = Colors.purpleAccent; break;
                case 'orange': glowColor = Colors.orangeAccent; break;
                default: glowColor = Colors.amber;
              }

              return GestureDetector(
                onLongPress: () => _showDeleteConfirmation(id, name),
                child: _buildDeviceCard(
                  icon: deviceIcon,
                  name: name,
                  room: room,
                  isActive: state,
                  onChanged: (v) => _networkService.toggleDeviceState(id, v),
                  glowColor: glowColor,
                  isWired: isWired,
                  port: port,
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Diagnostics Collapsible ExpansionTile
          _buildDiagnosticsTile(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  // ==================== ROOMS VIEW ====================
  Widget _buildRoomsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ROOMS HUB",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
              ),
              IconButton(
                icon: const Icon(Icons.add_home_rounded, color: Color(0xFF8E99F3)),
                onPressed: _showAddRoomDialog,
                tooltip: "Add Custom Room",
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable Room Status Cards
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: userRooms.length + 1,
              itemBuilder: (context, index) {
                if (index == userRooms.length) {
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: _showAddRoomDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: GlassContainer(
                        bgOpacity: 0.04,
                        padding: const EdgeInsets.all(12),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: Color(0xFF8E99F3), size: 24),
                            SizedBox(height: 6),
                            Text("Add Custom Room", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white54), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final String room = userRooms[index];
                final int totalDevicesInRoom = dynamicDevices.where((d) => d["room"] == room).length + (room == "Bedroom" ? 1 : 0);
                final int activeDevicesInRoom = dynamicDevices.where((d) => d["room"] == room && d["state"] == true).length + (room == "Bedroom" && acState ? 1 : 0);

                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
                  child: GlassContainer(
                    glowColor: activeDevicesInRoom > 0 ? const Color(0xFF8E99F3) : null,
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              room,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$activeDevicesInRoom / $totalDevicesInRoom Active",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: activeDevicesInRoom > 0 ? Colors.greenAccent : Colors.white38),
                            ),
                          ],
                        ),
                        // Delete Button for Custom Room if empty
                        if (!["Living Room", "Bedroom", "Kitchen", "Smart Office"].contains(room))
                          Positioned(
                            right: -8,
                            top: -8,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white38),
                              onPressed: () {
                                if (totalDevicesInRoom > 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Cannot delete a room that contains registered devices.")),
                                  );
                                  return;
                                }
                                setState(() {
                                  userRooms.remove(room);
                                  _logEvent("Deleted empty custom room: $room");
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Filter Chip / Room Climates Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DEVICES IN ${activeRoom.toUpperCase()}",
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1.0),
              ),
              Text(
                activeRoom == "All Rooms" ? "All Telemetry Sync" : "Local Room Synced",
                style: const TextStyle(fontSize: 8.5, color: Colors.white24, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List of filtered devices with Move command
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (activeRoom == "All Rooms" || activeRoom == "Bedroom" ? 1 : 0) +
                dynamicDevices.where((d) => activeRoom == "All Rooms" || d["room"] == activeRoom).length,
            itemBuilder: (context, index) {
              final filteredDevices = activeRoom == "All Rooms"
                  ? dynamicDevices
                  : dynamicDevices.where((d) => d["room"] == activeRoom).toList();

              final bool showAC = activeRoom == "All Rooms" || activeRoom == "Bedroom";
              if (showAC && index == 1) {
                // Return AC card in Rooms too!
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 68,
                  child: _buildACCard(),
                );
              }

              int deviceIndex = index;
              if (showAC && index > 1) {
                deviceIndex = index - 1;
              }

              if (deviceIndex >= filteredDevices.length || deviceIndex < 0) {
                return const SizedBox.shrink();
              }

              final device = filteredDevices[deviceIndex];
              final String id = device["id"] ?? "";
              final String name = device["name"] ?? "";
              final String room = device["room"] ?? "";
              final bool isWired = device["isWired"] ?? false;
              final int? port = device["port"];
              final bool state = device["state"] ?? false;
              final String iconStr = device["icon"] ?? "lightbulb";
              final String glowColorStr = device["glowColor"] ?? "amber";

              IconData deviceIcon;
              switch (iconStr) {
                case 'lightbulb': deviceIcon = Icons.lightbulb_outline_rounded; break;
                case 'air': deviceIcon = Icons.air_rounded; break;
                case 'videocam': deviceIcon = Icons.videocam_rounded; break;
                case 'fan': deviceIcon = Icons.toys_rounded; break;
                case 'outlet': deviceIcon = Icons.power_rounded; break;
                case 'tv': deviceIcon = Icons.tv_rounded; break;
                default: deviceIcon = Icons.device_unknown_rounded;
              }

              Color glowColor;
              switch (glowColorStr) {
                case 'amber': glowColor = Colors.amber; break;
                case 'teal': glowColor = Colors.tealAccent; break;
                case 'blue': glowColor = Colors.blueAccent; break;
                case 'purple': glowColor = Colors.purpleAccent; break;
                case 'orange': glowColor = Colors.orangeAccent; break;
                default: glowColor = Colors.amber;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  glowColor: state ? glowColor : null,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(deviceIcon, color: state ? glowColor : Colors.white24, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text("Room: $room ${isWired ? '• Pin $port' : ''}", style: const TextStyle(fontSize: 8.5, color: Colors.white38)),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: state,
                          activeColor: glowColor,
                          onChanged: (v) => _networkService.toggleDeviceState(id, v),
                        ),
                      ),
                      // Relocate Action Icon
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.drive_file_move_rounded, color: Color(0xFF8E99F3), size: 18),
                        tooltip: "Relocate Device",
                        dropdownColor: const Color(0xFF101323),
                        onSelected: (String targetRoom) {
                          _networkService.updateDeviceRoom(id, targetRoom);
                          _logEvent("Relocated device '$name' to room '$targetRoom'");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Moved '$name' to $targetRoom.")),
                          );
                        },
                        itemBuilder: (BuildContext context) {
                          return userRooms.map((String r) {
                            return PopupMenuItem<String>(
                              value: r,
                              child: Text(r, style: const TextStyle(color: Colors.white, fontSize: 11)),
                            );
                          }).toList();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showAddRoomDialog() {
    final roomController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            bgOpacity: 0.1,
            glowColor: const Color(0xFF8E99F3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "ADD CUSTOM ROOM",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Type a name for the new room. It will immediately be available in your dashboard room filters and relocation menus.",
                  style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: roomController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "e.g., Home Theater",
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    filled: true,
                    fillColor: Colors.black12,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF8E99F3)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C6BC0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final String name = roomController.text.trim();
                        if (name.isEmpty) return;
                        if (userRooms.contains(name)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Room name already exists.")));
                          return;
                        }
                        setState(() {
                          userRooms.add(name);
                          _logEvent("Added custom room: $name");
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("ADD ROOM", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== AUTOMATIONS VIEW ====================
  Widget _buildAutomationsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ROUTINES & SCENES",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
              ),
              IconButton(
                icon: const Icon(Icons.add_to_photos_rounded, color: Color(0xFF8E99F3)),
                onPressed: _showAddRuleDialog,
                tooltip: "Add Automation Rule",
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vibrant scene triggers in responsive grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              _buildLargeSceneCard("Away Mode", Icons.exit_to_app_rounded, "Away", "Shuts off lights, arms security node", const Color(0xFFE57373)),
              _buildLargeSceneCard("Movie Night", Icons.movie_filter_rounded, "Movie", "Dims lights, chilled temperature", const Color(0xFF64B5F6)),
              _buildLargeSceneCard("Sleep Mode", Icons.bedtime_rounded, "Sleep", "Halts appliances, warm bedroom", const Color(0xFF81C784)),
              _buildLargeSceneCard("Eco Saver", Icons.eco_rounded, "Eco", "Sets device relays to standby", const Color(0xFFFFB74D)),
            ],
          ),
          const SizedBox(height: 20),

          // Automation rules title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ACTIVE HARDWARE RULES",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1.0),
              ),
              Text(
                "${customRules.length} Rules Registered",
                style: const TextStyle(fontSize: 8.5, color: Colors.white24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Automation list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: customRules.length,
            itemBuilder: (context, index) {
              final rule = customRules[index];
              final bool isEnabled = rule["enabled"] == "true";

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  glowColor: isEnabled ? const Color(0xFF8E99F3) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isEnabled ? const Color(0xFF8E99F3).withOpacity(0.12) : Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.settings_input_composite_rounded, color: isEnabled ? const Color(0xFF8E99F3) : Colors.white38, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rule["trigger"] ?? "", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 3),
                            Text("Action: ${rule['action']}", style: const TextStyle(fontSize: 9, color: Colors.white54)),
                          ],
                        ),
                      ),
                      Switch(
                        value: isEnabled,
                        activeColor: const Color(0xFF8E99F3),
                        onChanged: (v) {
                          setState(() {
                            customRules[index]["enabled"] = v ? "true" : "false";
                            _logEvent("Automation rule '${rule['trigger']}' set to ${v ? 'ENABLED' : 'DISABLED'}");
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        onPressed: () {
                          setState(() {
                            _logEvent("Deleted automation rule: ${rule['trigger']}");
                            customRules.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLargeSceneCard(String title, IconData icon, String sceneName, String desc, Color color) {
    return InkWell(
      onTap: () => _triggerScene(sceneName),
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        bgOpacity: 0.05,
        glowColor: color.withOpacity(0.1),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 2),
            Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  void _showAddRuleDialog() {
    String selectedTrigger = "If Temperature > 28°C";
    String selectedAction = "Turn ON Air Purifier";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                bgOpacity: 0.1,
                glowColor: const Color(0xFF8E99F3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "ADD AUTOMATION RULE",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 16),
                    
                    // Trigger Dropdown
                    const Text("SELECT TRIGGER CONDITIONS", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white54)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButton<String>(
                        value: selectedTrigger,
                        dropdownColor: const Color(0xFF101323),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        underline: const SizedBox(),
                        isExpanded: true,
                        items: [
                          "If Temperature > 28°C",
                          "If Temperature < 18°C",
                          "If Humidity > 70%",
                          "If Sunset",
                          "If Motion Sensor Triggered"
                        ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedTrigger = v);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Dropdown
                    const Text("SELECT HARDWARE ACTION", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white54)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButton<String>(
                        value: selectedAction,
                        dropdownColor: const Color(0xFF101323),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        underline: const SizedBox(),
                        isExpanded: true,
                        items: [
                          "Turn ON Air Purifier",
                          "Turn OFF All Lights",
                          "Toggle Smart A/C",
                          "Arm Security System",
                          "Flash Primary Relays"
                        ].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedAction = v);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C6BC0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            setState(() {
                              customRules.add({
                                "trigger": selectedTrigger,
                                "action": selectedAction,
                                "enabled": "true",
                              });
                              _logEvent("Configured new automation rule: $selectedTrigger -> $selectedAction");
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("SAVE RULE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== SECURITY VIEW ====================
  Widget _buildSecurityView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            "SECURITY PANEL",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),

          // Security Status Card
          GlassContainer(
            glowColor: securityArm ? const Color(0xFFE57373) : const Color(0xFF81C784),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  securityArm ? Icons.gavel_rounded : Icons.lock_open_rounded,
                  color: securityArm ? const Color(0xFFE57373) : const Color(0xFF81C784),
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        securityArm ? "SYSTEM ARMED (AWAY)" : "SYSTEM DISARMED",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: securityArm ? const Color(0xFFE57373) : const Color(0xFF81C784)),
                      ),
                      const SizedBox(height: 2),
                      const Text("Perimeter secure. 4 Nodes reporting healthy.", style: TextStyle(fontSize: 9, color: Colors.white38)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Keypad and CCTV split on mobile in vertical layout
          const Text(
            "SURVEILLANCE OVERLAY",
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          
          // Simulated scanning Camera View
          GlassContainer(
            height: 180,
            bgOpacity: 0.1,
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                // Camera grid background
                Container(
                  color: Colors.black38,
                  child: Center(
                    child: Icon(Icons.videocam_off_rounded, color: Colors.white.withOpacity(0.02), size: 60),
                  ),
                ),
                // Static Scanlines
                Positioned.fill(
                  child: Image.network(
                    "https://images.unsplash.com/photo-1557683316-973673baf926?auto=format&fit=crop&q=80&w=600",
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.04),
                  ),
                ),
                // Scanline glowing green bar
                const _CameraScanlineAnimation(),
                // Telemetry details overlay
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text("REC • LIVE FEED - $activeCamera", style: const TextStyle(fontSize: 8.5, color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Positioned(
                  top: 10,
                  right: 10,
                  child: Text("FPS: 30.2 • H.265", style: TextStyle(fontSize: 8.5, color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ISO 400 • shutter 1/60s", style: TextStyle(fontSize: 7.5, color: Colors.white.withOpacity(0.5))),
                      Text(DateTime.now().toIso8601String().substring(0, 19).replaceAll("T", " "), style: const TextStyle(fontSize: 8, color: Colors.white70, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                // Crosshairs
                Center(
                  child: Icon(Icons.center_focus_weak_rounded, color: Colors.greenAccent.withOpacity(0.3), size: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.sync_rounded, size: 14, color: Color(0xFF8E99F3)),
                label: const Text("CYCLE CAMERA FEED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E99F3))),
                onPressed: () {
                  setState(() {
                    if (activeCamera == "Front Porch") {
                      activeCamera = "Backyard Deck";
                    } else if (activeCamera == "Backyard Deck") {
                      activeCamera = "Interior Hallway";
                    } else {
                      activeCamera = "Front Porch";
                    }
                    _logEvent("Camera switched to feed: $activeCamera");
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Numeric Code Entry Pad
          Center(
            child: SizedBox(
              width: 250,
              child: Column(
                children: [
                  const Text("ENTER CONTROL AUTH CODE", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white30, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  // Display PIN row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final bool isEntered = index < enteredPin.length;
                      return Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isEntered ? const Color(0xFF8E99F3) : Colors.transparent,
                          border: Border.all(color: const Color(0xFF8E99F3), width: 1.5),
                          boxShadow: isEntered ? [BoxShadow(color: const Color(0xFF8E99F3).withOpacity(0.5), blurRadius: 4)] : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // Grid buttons
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      ...List.generate(9, (index) => _buildKeypadButton((index + 1).toString())),
                      _buildKeypadButton("C", color: Colors.redAccent.withOpacity(0.12)),
                      _buildKeypadButton("0"),
                      _buildKeypadButton("Enter", isConfirm: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String digit, {Color? color, bool isConfirm = false}) {
    return InkWell(
      onTap: () {
        setState(() {
          if (digit == "C") {
            enteredPin = "";
          } else if (digit == "Enter") {
            _verifyPasscode();
          } else {
            if (enteredPin.length < 4) {
              enteredPin += digit;
              if (enteredPin.length == 4) {
                _verifyPasscode();
              }
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: GlassContainer(
        bgOpacity: color != null ? 0.0 : 0.04,
        padding: EdgeInsets.zero,
        child: Center(
          child: isConfirm
              ? const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 20)
              : Text(
                  digit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: digit == "C" ? Colors.redAccent : Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  void _verifyPasscode() {
    if (enteredPin == "1234") {
      setState(() {
        securityArm = !securityArm;
        enteredPin = "";
        _logEvent("Security changed: System ${securityArm ? 'ARMED' : 'DISARMED'} successfully");
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passcode Verified! System ${securityArm ? 'Armed' : 'Disarmed'}."),
          backgroundColor: Colors.green.shade800,
        ),
      );
    } else {
      setState(() {
        enteredPin = "";
        _logEvent("Security Alarm: PIN violation attempt blocked");
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("ACCESS DENIED: Incorrect Security Pin."),
          backgroundColor: Colors.red.shade900,
        ),
      );
    }
  }

  // ==================== ANALYTICS VIEW ====================
  Widget _buildAnalyticsView(double curTemp, double curHum) {
    final List<double> weeklyPower = [12.4, 15.1, 14.8, 11.2, 13.5, 16.2, 14.0];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            "TELEMETRY ANALYTICS",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),

          // Stacked trend charts
          GlassContainer(
            height: 150,
            child: ClimateTrendsChart(
              dataPoints: tempHistory,
              lineColor: const Color(0xFFE57373),
              label: "TEMPERATURE HISTORY TREND (24H)",
              suffix: "°C",
            ),
          ),
          const SizedBox(height: 14),

          GlassContainer(
            height: 150,
            child: ClimateTrendsChart(
              dataPoints: humHistory,
              lineColor: const Color(0xFF64B5F6),
              label: "HUMIDITY HISTORY TREND (24H)",
              suffix: "%",
            ),
          ),
          const SizedBox(height: 14),

          // Custom Power consumption bar chart mock
          GlassContainer(
            height: 150,
            child: ClimateTrendsChart(
              dataPoints: weeklyPower,
              lineColor: const Color(0xFFFFB74D),
              label: "WEEKLY POWER CONSUMPTION LOAD (kWh)",
              suffix: " kWh",
            ),
          ),
          const SizedBox(height: 20),

          // Scrolling Event System Log
          const Text(
            "REAL-TIME LOG CONSOLE",
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: systemLogs.length,
            itemBuilder: (context, index) {
              final log = systemLogs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.dns_outlined, color: Color(0xFF8E99F3), size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log,
                        style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ==================== SETTINGS VIEW ====================
  Widget _buildSettingsView() {
    final hostController = TextEditingController(text: mdnsHost);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            "SYSTEM SETTINGS",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),

          // Host settings card
          const Text("LOCAL GATEWAY mDNS HOST", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white30, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          GlassContainer(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hostController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "aura-hub.local",
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6BC0).withOpacity(0.3),
                    side: const BorderSide(color: Color(0xFF8E99F3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () {
                    setState(() {
                      mdnsHost = hostController.text.trim();
                      _logEvent("Local gateway hostname set to: $mdnsHost");
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hostname updated successfully.")));
                  },
                  child: const Text("UPDATE", style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Firmware settings check card
          const Text("OVER-THE-AIR (OTA) FLASH RECOVERY", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white30, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          GlassContainer(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Firmware Version: v1.0.8", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 2),
                    Text("Last checked: Today 10:15 AM", style: TextStyle(fontSize: 8, color: Colors.white38)),
                  ],
                ),
                isCheckingOTA
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF8E99F3), strokeWidth: 2))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E99F3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onPressed: () {
                          setState(() {
                            isCheckingOTA = true;
                          });
                          Timer(const Duration(seconds: 2), () {
                            if (mounted) {
                              setState(() {
                                isCheckingOTA = false;
                                _logEvent("Firmware integrity check passed. Current: v1.0.8");
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("AURA Hub is secure. Firmware v1.0.8 up-to-date.")),
                              );
                            }
                          });
                        },
                        child: const Text("CHECK FOR OTA", style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contrast selector slider
          const Text("UI SCREEN CONTRAST LEVEL", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white30, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          GlassContainer(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.brightness_medium_rounded, color: Color(0xFF8E99F3), size: 18),
                Expanded(
                  child: Slider(
                    value: uiContrast,
                    min: 0.5,
                    max: 1.5,
                    activeColor: const Color(0xFF8E99F3),
                    inactiveColor: Colors.white12,
                    onChanged: (v) {
                      setState(() {
                        uiContrast = v;
                      });
                    },
                  ),
                ),
                Text("${(uiContrast * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'monospace')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Factory cache reset
          const Text("HARDWARE INTEGRITY AND PURGING", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white30, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          GlassContainer(
            glowColor: Colors.redAccent.withOpacity(0.1),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Erase local memory cache (equivalent to ESP32 Flash memory NVS format).",
                  style: TextStyle(fontSize: 9, color: Colors.white54, height: 1.3),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.12),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _showCacheResetConfirmation,
                  child: const Text("PURGE FLASH CACHE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showCacheResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            bgOpacity: 0.1,
            glowColor: const Color(0xFFE57373),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "FORMAT LOCAL STORAGE?",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Warning: This resets all active settings, credentials, and custom room assignments back to baseline hardware presets.",
                  style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE57373).withOpacity(0.2),
                        side: const BorderSide(color: Color(0xFFE57373)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() {
                          userRooms = ["Living Room", "Bedroom", "Kitchen", "Smart Office"];
                          mdnsHost = "aura-hub.local";
                          uiContrast = 1.0;
                          enteredPin = "";
                          _logEvent("Flash Storage Formatted: Restored baseline presets");
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("NVS Flash Storage Reset Successful."),
                            backgroundColor: Colors.red.shade900,
                          ),
                        );
                      },
                      child: const Text("PURGE ALL", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double curTemp = temperature ?? 24.5;
    final double curHum = humidity ?? 48.0;

    return Scaffold(
      key: _scaffoldKey,
      // Drawer (Sleek side-menu)
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF090A0F),
              Color(0xFF101323),
              Color(0xFF1A1D36),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ================== PREMIUM APP BAR ==================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const Column(
                      children: [
                        Text(
                          "AURA SMART",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                        ),
                        Text(
                          "MOBILE DASHBOARD",
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 1),
                        ),
                      ],
                    ),
                    _buildWeatherWidget(),
                  ],
                ),
              ),

              // ================== SCROLLABLE MOBILE BODY ==================
              Expanded(
                child: _buildMainContent(curTemp, curHum),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile Drawer
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF090A0F),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF090A0F), Color(0xFF13172C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6BC0).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.blur_on_rounded, color: Color(0xFF8E99F3), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("AURA SMART", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                      Text("SYSTEM NODE v1.0", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: Colors.white38)),
                    ],
                  ),
                ],
              ),
            ),
            _buildDrawerTile(Icons.dashboard_rounded, "Dashboard", active: selectedSection == "Dashboard"),
            _buildDrawerTile(Icons.meeting_room_rounded, "Rooms", active: selectedSection == "Rooms"),
            _buildDrawerTile(Icons.offline_bolt_rounded, "Automations", active: selectedSection == "Automations"),
            _buildDrawerTile(Icons.security_rounded, "Security Panel", active: selectedSection == "Security Panel"),
            _buildDrawerTile(Icons.bar_chart_rounded, "Analytics", active: selectedSection == "Analytics"),
            _buildDrawerTile(Icons.settings_rounded, "Settings", active: selectedSection == "Settings"),
            const Spacer(),
            // User Card
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF5C6BC0),
                      radius: 14,
                      child: const Icon(Icons.person, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 10),
                    const Text("Alaje Bash", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, {required bool active}) {
    return ListTile(
      leading: Icon(icon, color: active ? const Color(0xFF8E99F3) : Colors.white54, size: 20),
      title: Text(
        title,
        style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? Colors.white : Colors.white70),
      ),
      selected: active,
      onTap: () {
        setState(() {
          selectedSection = title;
        });
        Navigator.pop(context);
      },
    );
  }

  // Room Filters
  Widget _buildRoomFilters() {
    final List<String> rooms = ["All Rooms", ...userRooms];
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final bool isSelected = activeRoom == rooms[index];
          return Container(
            margin: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => setState(() => activeRoom = rooms[index]),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.08),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    rooms[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Simulated Weather Widget Compact
  Widget _buildWeatherWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 14),
          SizedBox(width: 6),
          Text(
            "31°C",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Scene Chips horizontal
  Widget _buildSceneChip(String text, IconData icon, String sceneName) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        onPressed: () => _triggerScene(sceneName),
        backgroundColor: Colors.white.withOpacity(0.04),
        side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        avatar: Icon(icon, color: const Color(0xFF8E99F3), size: 14),
        label: Text(
          text,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white70),
        ),
      ),
    );
  }

  // Device card builder
  Widget _buildDeviceCard({
    required IconData icon,
    required String name,
    required String room,
    required bool isActive,
    required ValueChanged<bool> onChanged,
    required Color glowColor,
    bool isWired = false,
    int? port,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      glowColor: isActive ? glowColor : null,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? glowColor.withOpacity(0.12) : Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? glowColor : Colors.white24,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Row(
                  children: [
                    Text(
                      room,
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: Colors.white38),
                    ),
                    if (isWired && port != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E99F3).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF8E99F3).withOpacity(0.3), width: 0.5),
                        ),
                        child: Text(
                          "PIN $port",
                          style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.bold, color: Color(0xFF8E99F3)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.65,
            child: Switch(
              value: isActive,
              activeColor: glowColor,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    final nameController = TextEditingController();
    String selectedRoom = "Living Room";
    bool isWired = false;
    int? selectedPort = 13; // default GPIO 13
    String selectedIcon = "lightbulb";
    String selectedGlow = "amber";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              content: GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                bgOpacity: 0.08,
                borderOpacity: 0.15,
                glowColor: const Color(0xFF8E99F3),
                glowBlurRadius: 18.0,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "REGISTER DEVICE",
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      
                      // Name Input
                      const Text(
                        "DEVICE NAME",
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "e.g., Dining Room Fan",
                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                          filled: true,
                          fillColor: Colors.black12,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF8E99F3)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Room Dropdown
                      const Text(
                        "ASSIGN ROOM LOCATION",
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: DropdownButton<String>(
                          value: selectedRoom,
                          dropdownColor: const Color(0xFF101323),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          underline: const SizedBox(),
                          isExpanded: true,
                          items: ["Living Room", "Bedroom", "Kitchen", "Office", "Bathroom", "Balcony"]
                              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setDialogState(() => selectedRoom = v);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Wired vs Wireless Toggle
                      const Text(
                        "HARDWARE INTERFACE TYPE",
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("WIRED PIN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              selected: isWired,
                              selectedColor: const Color(0xFF5C6BC0).withOpacity(0.3),
                              backgroundColor: Colors.transparent,
                              labelStyle: TextStyle(color: isWired ? Colors.white : Colors.white38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onSelected: (selected) {
                                setDialogState(() => isWired = true);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("WIRELESS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              selected: !isWired,
                              selectedColor: const Color(0xFF5C6BC0).withOpacity(0.3),
                              backgroundColor: Colors.transparent,
                              labelStyle: TextStyle(color: !isWired ? Colors.white : Colors.white38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onSelected: (selected) {
                                setDialogState(() => isWired = false);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Wired Port Selector (Omitted if Wireless)
                      if (isWired) ...[
                        const Text(
                          "SELECT DIRECT MCU PORT (GPIO PIN)",
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: DropdownButton<int>(
                            value: selectedPort,
                            dropdownColor: const Color(0xFF101323),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            underline: const SizedBox(),
                            isExpanded: true,
                            items: [2, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33]
                                .map((pin) => DropdownMenuItem(value: pin, child: Text("GPIO Pin $pin")))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedPort = v);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Icon category
                      const Text(
                        "DEVICE ICON SYMBOL",
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildIconChoice(setDialogState, "lightbulb", Icons.lightbulb_outline_rounded, selectedIcon, (v) => selectedIcon = v),
                          _buildIconChoice(setDialogState, "fan", Icons.toys_rounded, selectedIcon, (v) => selectedIcon = v),
                          _buildIconChoice(setDialogState, "air", Icons.air_rounded, selectedIcon, (v) => selectedIcon = v),
                          _buildIconChoice(setDialogState, "videocam", Icons.videocam_rounded, selectedIcon, (v) => selectedIcon = v),
                          _buildIconChoice(setDialogState, "outlet", Icons.power_rounded, selectedIcon, (v) => selectedIcon = v),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Glow Color choice
                      const Text(
                        "GLOW COLOR THEME",
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildColorChoice(setDialogState, "amber", Colors.amber, selectedGlow, (v) => selectedGlow = v),
                          _buildColorChoice(setDialogState, "teal", Colors.tealAccent, selectedGlow, (v) => selectedGlow = v),
                          _buildColorChoice(setDialogState, "blue", Colors.blueAccent, selectedGlow, (v) => selectedGlow = v),
                          _buildColorChoice(setDialogState, "purple", Colors.purpleAccent, selectedGlow, (v) => selectedGlow = v),
                          _buildColorChoice(setDialogState, "orange", Colors.orangeAccent, selectedGlow, (v) => selectedGlow = v),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Submit Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6BC0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please provide a valid device name.")),
                            );
                            return;
                          }
                          
                          final String newId = "device_${DateTime.now().millisecondsSinceEpoch}";
                          final Map<String, dynamic> newDevice = {
                            "id": newId,
                            "name": nameController.text.trim(),
                            "room": selectedRoom,
                            "isWired": isWired,
                            "port": isWired ? selectedPort : null,
                            "state": false,
                            "icon": selectedIcon,
                            "glowColor": selectedGlow,
                          };

                          _networkService.addDevice(newDevice);
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Registered '${nameController.text.trim()}' successfully."),
                              backgroundColor: Colors.green.shade800,
                            ),
                          );
                        },
                        child: const Text(
                          "PROVISION HARDWARE NODE",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIconChoice(StateSetter setDialogState, String key, IconData icon, String current, ValueChanged<String> onSelected) {
    final bool isSelected = current == key;
    return InkWell(
      onTap: () {
        setDialogState(() {
          onSelected(key);
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5C6BC0).withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: isSelected ? const Color(0xFF8E99F3) : Colors.white10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isSelected ? const Color(0xFF8E99F3) : Colors.white38, size: 18),
      ),
    );
  }

  Widget _buildColorChoice(StateSetter setDialogState, String key, Color color, String current, ValueChanged<String> onSelected) {
    final bool isSelected = current == key;
    return InkWell(
      onTap: () {
        setDialogState(() {
          onSelected(key);
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 1),
                ]
              : null,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String id, String name) {
    // Cannot delete the preloaded system lightbulb relay
    if (id == "device_lights") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot delete built-in primary system relay."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            bgOpacity: 0.1,
            glowColor: const Color(0xFFE57373),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "DEPROVISION NODE?",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                Text(
                  "Are you sure you want to remove the registered device '$name' from the AURA controller network?",
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE57373).withOpacity(0.2),
                        side: const BorderSide(color: Color(0xFFE57373)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _networkService.deleteDevice(id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Deprovisioned '$name' successfully."),
                            backgroundColor: Colors.red.shade900,
                          ),
                        );
                      },
                      child: const Text("DEPROVISION", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // A/C controller Card
  Widget _buildACCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(6),
      glowColor: acState ? Colors.cyan : null,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: acState ? Colors.cyan.withOpacity(0.12) : Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.ac_unit_rounded,
              color: acState ? Colors.cyanAccent : Colors.white24,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Smart A/C",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  acState ? "Cooling • ${acTargetTemp.toStringAsFixed(0)}°" : "AC Off",
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: acState ? Colors.cyanAccent : Colors.white38,
                  ),
                ),
                if (acState) ...[
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      _buildTempButton(Icons.remove, () {
                        if (acTargetTemp > 16) setState(() => acTargetTemp--);
                      }),
                      const SizedBox(width: 4),
                      _buildTempButton(Icons.add, () {
                        if (acTargetTemp < 30) setState(() => acTargetTemp++);
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Transform.scale(
            scale: 0.65,
            child: Switch(
              value: acState,
              activeColor: Colors.cyanAccent,
              onChanged: (v) => setState(() => acState = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(icon, color: Colors.white70, size: 8),
      ),
    );
  }

  // Collapsible Diagnostics panel
  Widget _buildDiagnosticsTile() {
    return GlassContainer(
      bgOpacity: 0.04,
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: const Text(
          "HARDWARE DIAGNOSTICS",
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white60, letterSpacing: 0.5),
        ),
        leading: const Icon(Icons.settings_input_hdmi_rounded, color: Color(0xFF8E99F3), size: 18),
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white38,
        childrenPadding: const EdgeInsets.all(12.0),
        shape: const Border(), // Removes bottom dividers
        children: [
          _buildDiagRow("IP ADDRESS", "192.168.1.145"),
          const SizedBox(height: 6),
          _buildDiagRow("WI-FI RSSI", "-48 dBm"),
          const SizedBox(height: 6),
          _buildDiagRow("FIRMWARE VER", "AURA.ESP32.v1.0.8"),
          const SizedBox(height: 6),
          _buildDiagRow("SYSTEM UPTIME", "4d 18h 32m"),
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.white38)),
        Text(value, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white70)),
      ],
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:smart_home_front_end/exports.dart';

// class MobileBody extends StatefulWidget {
//   const MobileBody({super.key});

//   @override
//   State<MobileBody> createState() => _MobileBodyState();
// }

// class _MobileBodyState extends State<MobileBody> {
//   String? temperature = "Loading..."; // Replace with dynamic data fetching
//   String? humidity = "Loading..."; // Replace with dynamic data fetching

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Smart Home'),
//         ),
//         backgroundColor: Colors.black26,
    //     body: SingleChildScrollView(
    //       child: Padding(
    //         padding: const EdgeInsets.all(16.0),
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             const SizedBox(height: 10),
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //               children: [
    //                 // Temperature
    //                 Expanded(
    //                   child: Card(
    //                     elevation: 4,
    //                     child: ListTile(
    //                       leading:
    //                           const Icon(Icons.thermostat, color: Colors.red),
    //                       title: const Text(
    //                         "Temperature",
    //                         style: TextStyle(fontWeight: FontWeight.bold),
    //                       ),
    //                       subtitle: Text(
    //                         "$temperature°C",
    //                         style: const TextStyle(fontSize: 16),
    //                       ),
    //                     ),
    //                   ),
    //                 ),
    //                 const SizedBox(width: 10),
    //                 // Humidity
    //                 Expanded(
    //                   child: Card(
    //                     elevation: 4,
    //                     child: ListTile(
    //                       leading:
    //                           const Icon(Icons.water_drop, color: Colors.blue),
    //                       title: const Text(
    //                         "Humidity",
    //                         style: TextStyle(fontWeight: FontWeight.bold),
    //                       ),
    //                       subtitle: Text(
    //                         "$humidity%",
    //                         style: const TextStyle(fontSize: 16),
    //                       ),
    //                     ),
    //                   ),
    //                 ),
    //               ],
    //             ),
    //             const SizedBox(height: 10),
    //             // Temperature and Humidity Row
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //               children: [
    //                 Row(
    //                   children: [
    //                     Padding(
    //                       padding: const EdgeInsets.all(8.0),
    //                       child: Card(
    //                         elevation: 4,
    //                         child: TemperatureGauge(
    //                           temperature: 26,
    //                         ),
    //                       ),
    //                     ),
    //                     Padding(
    //                       padding: const EdgeInsets.all(8.0),
    //                       child: Card(

    //                         elevation: 4,
    //                         child: HumidityGauge(
    //                           humidity: 70,
    //                         ),
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //                 SizedBox(
    //                   width: 5,
    //                   height: 10,
    //                 ),
    //                 // Temperature
    //               ],
    //             ),
    //             const SizedBox(height: 20),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
//   }
// }




// Expanded(
//                       child: Card(
//                         elevation: 4,
//                         child: ListTile(
//                           leading:
//                               const Icon(Icons.thermostat, color: Colors.red),
//                           title: const Text(
//                             "Temperature",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(
//                             "$temperature°C",
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     // Humidity
//                     Expanded(
//                       child: Card(
//                         elevation: 4,
//                         child: ListTile(
//                           leading:
//                               const Icon(Icons.water_drop, color: Colors.blue),
//                           title: const Text(
//                             "Humidity",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(
//                             "$humidity%",
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                         ),
//                       ),
//                     ),







// //  Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Row(
//               children: [
//                 TemperatureGauge(temperature: temperature),
//                 const SizedBox(height: 20),
//                 HumidityGauge(humidity: humidity),
//                 const SizedBox(height: 20),
//               ],
            //     Card(
            //       elevation: 4,
            //       child: ListTile(
            //         leading: Icon(
            //           Icons.lightbulb,
            //           color: relayState ? Colors.green : Colors.grey,
            //         ),
            //         title: const Text(
            //           "Light Relay",
            //           style: TextStyle(fontWeight: FontWeight.bold),
            //         ),
            //         trailing: Switch(
            //           value: relayState,
            //           onChanged: (value) {
            //             _toggleRelayState(value);
            //           },
            //         ),
            //       ),
            //     ),
          
            // ),
//           ],
//         ),
//       ),

class _CameraScanlineAnimation extends StatefulWidget {
  const _CameraScanlineAnimation({Key? key}) : super(key: key);

  @override
  State<_CameraScanlineAnimation> createState() => _CameraScanlineAnimationState();
}

class _CameraScanlineAnimationState extends State<_CameraScanlineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: _controller.value * 180,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.greenAccent.withOpacity(0.0),
                  Colors.greenAccent.withOpacity(0.8),
                  Colors.greenAccent.withOpacity(0.0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}