import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_home_front_end/exports.dart';

class TabletBody extends StatefulWidget {
  const TabletBody({super.key});

  @override
  State<TabletBody> createState() => _TabletBodyState();
}

class _TabletBodyState extends State<TabletBody> {
  final NetworkService _networkService = NetworkService();

  // Real-time diagnostics state
  bool isEspOnline = false;
  String espIp = "0.0.0.0";
  int espRssi = -100;
  int espFreeHeap = 0;
  String espUptime = "Offline";
  StreamSubscription? _diagnosticsSub;

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

  // Active status filter
  String activeStatusFilter = "All";

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
  String mdnsHost = "aminai-hub.local";

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

  Widget _buildPulsingStatusPill() {
    final color = isEspOnline ? const Color(0xFF81C784) : const Color(0xFFE57373);
    final text = isEspOnline ? "HUB ONLINE" : "HUB OFFLINE";
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: isEspOnline ? [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ] : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getRssiLabel(int rssi) {
    if (rssi == -100) return "(Offline)";
    if (rssi >= -50) return "(Excellent)";
    if (rssi >= -70) return "(Good)";
    if (rssi >= -85) return "(Fair)";
    return "(Poor)";
  }

  void _triggerReboot() {
    _networkService.rebootController();
    _logEvent("Issued remote system reboot command to ESP32 Hub");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Reboot command transmitted to ESP32 hub successfully."),
        backgroundColor: Colors.amber.shade900,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Real-time chart history lists
  final List<double> tempHistory = [22.4, 22.8, 23.1, 23.5, 23.8, 24.2, 24.5, 24.3, 24.0, 23.8, 24.1, 24.4];
  final List<double> humHistory = [45.0, 46.2, 47.1, 48.5, 49.0, 50.2, 51.5, 52.0, 51.1, 49.5, 48.0, 48.8];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    _diagnosticsSub?.cancel();
    _networkService.dispose();
    super.dispose();
  }

  void _initializeData() {
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

    _devicesSub = _networkService.listenToDevices().listen((devicesList) {
      if (mounted) {
        setState(() {
          dynamicDevices = devicesList;
          final lightDevice = devicesList.firstWhere((d) => d["id"] == "device_lights", orElse: () => {});
          if (lightDevice.isNotEmpty) {
            relayState = lightDevice["state"] ?? false;
          }
        });
      }
    });

    _diagnosticsSub = _networkService.listenToDiagnostics().listen((diag) {
      if (mounted) {
        setState(() {
          isEspOnline = diag["online"] ?? false;
          espIp = diag["ip"] ?? "0.0.0.0";
          espRssi = diag["rssi"] ?? -100;
          espFreeHeap = diag["free_heap"] ?? 0;
          espUptime = diag["uptime"] ?? "Offline";
        });
      }
    });
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
      case "Devices":
        return _buildDevicesTabView();
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

  // ==================== DASHBOARD VIEW (TABLET EXCLUSIVE) ====================
  Widget _buildDashboardView(double curTemp, double curHum) {
    double displayTemp = curTemp;
    double displayHum = curHum;
    List<double> displayTempHistory = tempHistory;
    List<double> displayHumHistory = humHistory;
    if (activeRoom != "All Rooms") {
      final double offsetTemp = (activeRoom.length % 3 - 1) * 1.2;
      final double offsetHum = (activeRoom.length % 5 - 2) * 3.0;
      displayTemp = curTemp + offsetTemp;
      displayHum = curHum + offsetHum;
      displayTempHistory = tempHistory.map((t) => double.parse((t + offsetTemp).toStringAsFixed(1))).toList();
      displayHumHistory = humHistory.map((h) => double.parse((h + offsetHum).toStringAsFixed(1))).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Area
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      activeRoom == "All Rooms" ? "Bash Smart Hub" : "$activeRoom View",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                    ),
                    const SizedBox(width: 15),
                    _buildPulsingStatusPill(),
                    if (activeRoom != "All Rooms") ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            activeRoom = "All Rooms";
                          });
                        },
                        icon: const Icon(Icons.clear_rounded, size: 14, color: Color(0xFF8E99F3)),
                        label: const Text(
                          "Show All",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E99F3)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Secure Local Tablet Interface",
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.35)),
                ),
              ],
            ),
            _buildWeatherWidget(),
          ],
        ),
        const SizedBox(height: 20),

        // Room Selection Bar
        _buildRoomFilters(),
        const SizedBox(height: 20),

        // Main 2-Column Split
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT GRID: Telemetry & Devices (flex: 11)
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gauges row
                  Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
                          glowColor: const Color(0xFFE57373),
                          child: Column(
                            children: [
                              const Text("Temp Node", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                              const SizedBox(height: 10),
                              TemperatureGauge(temperature: displayTemp),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassContainer(
                          glowColor: const Color(0xFF64B5F6),
                          child: Column(
                            children: [
                              const Text("Humidity Node", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                              const SizedBox(height: 10),
                              HumidityGauge(humidity: displayHum),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Devices Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "CONNECTED DEVICES",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1.0),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF8E99F3), size: 22),
                        onPressed: _showAddDeviceDialog,
                        tooltip: "Register New Hardware Device",
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatusFilters(),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: (() {
                      final roomFiltered = activeRoom == "All Rooms"
                          ? dynamicDevices
                          : dynamicDevices.where((d) => d["room"] == activeRoom).toList();
                      final statusFiltered = roomFiltered.where((d) {
                        final status = d["status"] ?? "online";
                        if (activeStatusFilter == "All") return true;
                        if (activeStatusFilter == "Online") return status == "online";
                        if (activeStatusFilter == "Offline") return status == "offline";
                        if (activeStatusFilter == "Faulty") return status == "faulty";
                        return true;
                      }).toList();

                      final bool showAC = (activeRoom == "All Rooms" || activeRoom == "Bedroom") &&
                          (activeStatusFilter == "All" || activeStatusFilter == "Online");
                      return (showAC ? 1 : 0) + statusFiltered.length;
                    })(),
                    itemBuilder: (context, index) {
                      final roomFiltered = activeRoom == "All Rooms"
                          ? dynamicDevices
                          : dynamicDevices.where((d) => d["room"] == activeRoom).toList();
                      final statusFiltered = roomFiltered.where((d) {
                        final status = d["status"] ?? "online";
                        if (activeStatusFilter == "All") return true;
                        if (activeStatusFilter == "Online") return status == "online";
                        if (activeStatusFilter == "Offline") return status == "offline";
                        if (activeStatusFilter == "Faulty") return status == "faulty";
                        return true;
                      }).toList();

                      final bool showAC = (activeRoom == "All Rooms" || activeRoom == "Bedroom") &&
                          (activeStatusFilter == "All" || activeStatusFilter == "Online");

                      if (showAC && index == 0) {
                        return _buildACCard();
                      }

                      int deviceIndex = index;
                      if (showAC) {
                        deviceIndex = index - 1;
                      }

                      if (deviceIndex >= statusFiltered.length || deviceIndex < 0) {
                        return const SizedBox.shrink();
                      }

                      final device = statusFiltered[deviceIndex];
                      final String id = device["id"] ?? "";
                      final String name = device["name"] ?? "";
                      final String room = device["room"] ?? "";
                      final bool isWired = device["isWired"] ?? false;
                      final int? port = device["port"];
                      final bool state = device["state"] ?? false;
                      final String iconStr = device["icon"] ?? "lightbulb";
                      final String glowColorStr = device["glowColor"] ?? "amber";
                      final String status = device["status"] ?? "online";
                      final String direction = device["direction"] ?? "output";
                      final String valueType = device["valueType"] ?? "binary";
                      final dynamic value = device["value"];

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
                          id: id,
                          icon: deviceIcon,
                          name: name,
                          room: room,
                          isActive: state,
                          onChanged: (v) => _networkService.toggleDeviceState(id, v),
                          glowColor: glowColor,
                          isWired: isWired,
                          port: port,
                          status: status,
                          direction: direction,
                          valueType: valueType,
                          value: value,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // RIGHT COLUMN: Analytics, Scenes & Diagnostics (flex: 9)
            Expanded(
              flex: 9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trends Chart
                  GlassContainer(
                    height: 180,
                    child: ClimateTrendsChart(
                      dataPoints: displayTempHistory,
                      lineColor: const Color(0xFFE57373),
                      label: activeRoom == "All Rooms" ? "TEMPERATURE HISTORY (24H)" : "${activeRoom.toUpperCase()} TEMPERATURE HISTORY (24H)",
                      suffix: "°C",
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scenes Row
                  const Text(
                    "SCENES & AUTOMATION",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildCompactSceneButton("Away", Icons.exit_to_app_rounded, "Away")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactSceneButton("Movie", Icons.movie_filter_rounded, "Movie")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactSceneButton("Sleep", Icons.bedtime_rounded, "Sleep")),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Diagnostics Panel
                  const Text(
                    "HARDWARE DIAGNOSTICS",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 10),
                  GlassContainer(
                    bgOpacity: 0.05,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDiagRow("IP ADDRESS", espIp),
                        const Divider(color: Colors.white10, height: 12),
                        _buildDiagRow("WI-FI STRENGTH", "$espRssi dBm ${_getRssiLabel(espRssi)}"),
                        const Divider(color: Colors.white10, height: 12),
                        _buildDiagRow("FREE HEAP MEM", "${(espFreeHeap / 1024).toStringAsFixed(1)} KB"),
                        const Divider(color: Colors.white10, height: 12),
                        _buildDiagRow("SYSTEM UPTIME", espUptime),
                        const Divider(color: Colors.white10, height: 16),
                        ElevatedButton.icon(
                          onPressed: isEspOnline ? _triggerReboot : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE57373).withOpacity(0.12),
                            disabledBackgroundColor: Colors.white10,
                            foregroundColor: const Color(0xFFE57373),
                            disabledForegroundColor: Colors.white24,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isEspOnline ? const Color(0xFFE57373).withOpacity(0.3) : Colors.transparent,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.restart_alt_rounded, size: 14),
                          label: const Text(
                            "REBOOT CONTROLLER",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== DEVICES VIEW ====================
  Widget _buildMetricTile(String label, String value, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      glowColor: color.withOpacity(0.3),
      borderRadius: 12,
      bgOpacity: 0.05,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.35), letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesTabView() {
    final onlineCount = dynamicDevices.where((d) => (d["status"] ?? "online") == "online").length + 1; // including AC
    final offlineCount = dynamicDevices.where((d) => (d["status"] ?? "online") == "offline").length;
    final faultyCount = dynamicDevices.where((d) => (d["status"] ?? "online") == "faulty").length;
    final totalCount = onlineCount + offlineCount + faultyCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Devices Hub",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                ),
                SizedBox(height: 4),
                Text(
                  "View, relocate, and manage registered hardware nodes",
                  style: TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF8E99F3), size: 24),
              onPressed: _showAddDeviceDialog,
              tooltip: "Register New Hardware Device",
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildMetricTile("TOTAL", totalCount.toString(), const Color(0xFF8E99F3)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile("ONLINE", onlineCount.toString(), const Color(0xFF81C784)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile("OFFLINE", offlineCount.toString(), const Color(0xFF90A4AE)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile("FAULTY", faultyCount.toString(), const Color(0xFFE57373)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const Text(
          "REGISTERED HARDWARE NODES",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dynamicDevices.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildDevicesTabCard(
                id: "device_ac",
                name: "Climate AC unit",
                room: "Bedroom",
                isWired: false,
                port: null,
                state: acState,
                icon: "ac_unit",
                glowColor: "blue",
                status: "online",
                isAC: true,
              );
            }
            final device = dynamicDevices[index - 1];
            return _buildDevicesTabCard(
              id: device["id"],
              name: device["name"] ?? "",
              room: device["room"] ?? "",
              isWired: device["isWired"] ?? false,
              port: device["port"],
              state: device["state"] ?? false,
              icon: device["icon"] ?? "lightbulb",
              glowColor: device["glowColor"] ?? "amber",
              status: device["status"] ?? "online",
              isAC: false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDevicesTabCard({
    required String id,
    required String name,
    required String room,
    required bool isWired,
    required int? port,
    required bool state,
    required String icon,
    required String glowColor,
    required String status,
    required bool isAC,
  }) {
    IconData deviceIcon;
    switch (icon) {
      case 'toys':
      case 'fan':
        deviceIcon = Icons.toys_rounded;
        break;
      case 'air':
        deviceIcon = Icons.air_rounded;
        break;
      case 'videocam':
        deviceIcon = Icons.videocam_rounded;
        break;
      case 'outlet':
      case 'power':
        deviceIcon = Icons.power_rounded;
        break;
      case 'ac_unit':
        deviceIcon = Icons.ac_unit_rounded;
        break;
      default:
        deviceIcon = Icons.lightbulb_outline_rounded;
    }

    Color color;
    switch (glowColor) {
      case 'teal':
        color = Colors.tealAccent;
        break;
      case 'blue':
        color = Colors.blueAccent;
        break;
      case 'purple':
        color = Colors.purpleAccent;
        break;
      case 'orange':
        color = Colors.orangeAccent;
        break;
      default:
        color = Colors.amber;
    }

    Color statusColor;
    String statusText;
    switch (status) {
      case 'offline':
        statusColor = Colors.grey.shade500;
        statusText = "OFFLINE";
        break;
      case 'faulty':
        statusColor = const Color(0xFFE57373);
        statusText = "FAULTY";
        break;
      default:
        statusColor = const Color(0xFF81C784);
        statusText = "ONLINE";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 16,
        glowColor: state ? color : Colors.transparent,
        bgOpacity: 0.05,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: state ? color.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
                border: Border.all(
                  color: state ? color.withOpacity(0.25) : Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Icon(deviceIcon, color: state ? color : Colors.white60, size: 20),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "Room: $room",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.5)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "•",
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isWired ? "Wired GPIO $port" : "Wireless ESP-NOW",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.drive_file_move_rounded, color: Colors.white.withOpacity(0.4), size: 18),
                  tooltip: "Move device to another room",
                  onSelected: (String newRoom) async {
                    if (isAC) {
                      _logEvent("Relocated mock Climate AC unit to $newRoom");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Relocated Climate AC unit to $newRoom")),
                      );
                    } else {
                      await _networkService.updateDeviceRoom(id, newRoom);
                      _logEvent("Relocated device '$name' to $newRoom");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Relocated '$name' to $newRoom")),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return userRooms.map((String rm) {
                      return PopupMenuItem<String>(
                        value: rm,
                        child: Text(
                          rm,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      );
                    }).toList();
                  },
                ),

                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: state,
                    activeColor: const Color(0xFF8E99F3),
                    activeTrackColor: const Color(0xFF8E99F3).withOpacity(0.35),
                    inactiveThumbColor: Colors.white54,
                    inactiveTrackColor: Colors.white10,
                    onChanged: (bool value) {
                      if (isAC) {
                        setState(() {
                          acState = value;
                        });
                        _logEvent("Turned ${value ? 'ON' : 'OFF'} mock Climate AC unit");
                      } else {
                        _networkService.toggleDeviceState(id, value);
                        _logEvent("Toggled state for $name to ${value ? 'ON' : 'OFF'}");
                      }
                    },
                  ),
                ),

                if (!isAC)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE57373), size: 18),
                    tooltip: "Remove from system",
                    onPressed: () => _confirmDeleteDevice(id, name),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDevice(String id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          content: GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(24),
            bgOpacity: 0.08,
            borderOpacity: 0.15,
            glowColor: const Color(0xFFE57373),
            glowBlurRadius: 18.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CONFIRM DELETION",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                ),
                const SizedBox(height: 10),
                Text(
                  "Are you sure you want to permanently remove '$name' from the smart home network? This will detach its hardware binding.",
                  style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
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
                      onPressed: () async {
                        Navigator.pop(context);
                        await _networkService.deleteDevice(id);
                        _logEvent("Deleted device '$name' successfully.");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Successfully removed '$name' from system."),
                            backgroundColor: Colors.red.shade900,
                          ),
                        );
                      },
                      child: const Text("DELETE DEVICE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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

  // ==================== ROOMS VIEW ====================
  Widget _buildRoomsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Rooms Hub",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  "Manage room zones and relocate appliances",
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.35)),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_home_rounded, color: Color(0xFF8E99F3)),
              onPressed: _showAddRoomDialog,
              tooltip: "Create New Custom Room",
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Horizontal status list
        SizedBox(
          height: 90,
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
                          Icon(Icons.add_circle_outline_rounded, color: Color(0xFF8E99F3), size: 22),
                          SizedBox(height: 4),
                          Text("Add Room", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white54)),
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
                child: InkWell(
                  onTap: () {
                    setState(() {
                      activeRoom = room;
                      selectedSection = "Dashboard";
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: GlassContainer(
                    glowColor: activeDevicesInRoom > 0 ? const Color(0xFF8E99F3) : null,
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(room, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
                            const SizedBox(height: 4),
                            Text("$totalDevicesInRoom Nodes Total", style: const TextStyle(fontSize: 9, color: Colors.white38)),
                            Text("$activeDevicesInRoom Active Now", style: TextStyle(fontSize: 9, color: activeDevicesInRoom > 0 ? const Color(0xFF8E99F3) : Colors.white24)),
                          ],
                        ),
                        if (room != "Living Room" && room != "Bedroom" && room != "Kitchen" && room != "Smart Office")
                          Positioned(
                            top: -6,
                            right: -6,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 14),
                              onPressed: () {
                                if (totalDevicesInRoom > 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Cannot delete a room that still contains appliances. Relocate them first.")),
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
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // 2-Column Split
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Room statistics badge
            Expanded(
              flex: 4,
              child: GlassContainer(
                bgOpacity: 0.05,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ZONE STATISTICS", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    _buildStatRow("Total System Zones", "${userRooms.length}"),
                    const Divider(color: Colors.white10),
                    _buildStatRow("Cloud Firebase Link", "Connected"),
                    const Divider(color: Colors.white10),
                    _buildStatRow("mDNS Multicast Status", "v4 Polling Active"),
                    const SizedBox(height: 20),
                    const Text(
                      "To move any appliance, press and hold (long-press) or click the 'Move to Room' trigger below the device's card.",
                      style: TextStyle(fontSize: 10, color: Colors.white38, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Right Side: Filtered appliances list
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ZONE APPLIANCES", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  dynamicDevices.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text("No appliances registered yet", style: TextStyle(color: Colors.white38, fontSize: 12))))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dynamicDevices.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final device = dynamicDevices[index];
                            final String id = device["id"] ?? "";
                            final String name = device["name"] ?? "";
                            final String room = device["room"] ?? "";
                            return GlassContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              bgOpacity: 0.06,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                      const SizedBox(height: 2),
                                      Text("Located in: $room", style: const TextStyle(fontSize: 9.5, color: Colors.white38)),
                                    ],
                                  ),
                                  DropdownButton<String>(
                                    value: room,
                                    dropdownColor: const Color(0xFF101323),
                                    style: const TextStyle(color: Color(0xFF8E99F3), fontSize: 11, fontWeight: FontWeight.bold),
                                    underline: const SizedBox(),
                                    items: userRooms.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                                    onChanged: (newRoom) {
                                      if (newRoom != null && newRoom != room) {
                                        _networkService.updateDeviceRoom(id, newRoom);
                                        _logEvent("Relocated device '$name' to '$newRoom'");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Relocated '$name' to '$newRoom' successfully.")),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper row for Rooms View
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  // ==================== AUTOMATIONS VIEW (TABLET EXCLUSIVE) ====================
  Widget _buildAutomationsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Automations Hub",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  "Configure direct scene macros and routine triggers",
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.35)),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF8E99F3)),
              onPressed: _showAddRuleDialog,
              tooltip: "Build Custom Automation Rule",
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2-Column Split
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (flex: 1): Direct Scene Actions
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("DIRECT SCENE TRIGGER CAPSULES", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  _buildLargeSceneCard("Away Mode", Icons.exit_to_app_rounded, "Away", "Shuts off all lights, locks security panel, and halts AC/purifiers.", const Color(0xFFE57373)),
                  const SizedBox(height: 12),
                  _buildLargeSceneCard("Cinema Mode", Icons.movie_filter_rounded, "Movie", "Sets room light state to OFF, AC state to active (21°C), and blinds down.", const Color(0xFF8E99F3)),
                  const SizedBox(height: 12),
                  _buildLargeSceneCard("Good Night", Icons.bedtime_rounded, "Sleep", "Toggles primary relays, sets dim lighting, AC to 23°C, and arms alarms.", const Color(0xFF64B5F6)),
                  const SizedBox(height: 12),
                  _buildLargeSceneCard("Eco Saver", Icons.eco_rounded, "Eco", "Disables heavy climate loads and activates air purification systems.", const Color(0xFF81C784)),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // Right Column (flex: 1): Custom Rules Engine
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("DYNAMIC RULE CONTROLLER", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: customRules.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final rule = customRules[index];
                      final bool isEnabled = rule["enabled"] == "true";
                      return GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        bgOpacity: 0.05,
                        glowColor: isEnabled ? const Color(0xFF8E99F3) : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rule["trigger"] ?? "", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.greenAccent),
                                      const SizedBox(width: 4),
                                      Text(rule["action"] ?? "", style: const TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isEnabled,
                              activeColor: const Color(0xFF8E99F3),
                              onChanged: (val) {
                                setState(() {
                                  rule["enabled"] = val ? "true" : "false";
                                  _logEvent("Toggled automation rule: ${rule['trigger']} -> $val");
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLargeSceneCard(String title, IconData icon, String sceneName, String desc, Color color) {
    return InkWell(
      onTap: () => _triggerScene(sceneName),
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        glowColor: color,
        bgOpacity: 0.06,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 10, color: Colors.white54, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SECURITY VIEW (TABLET EXCLUSIVE) ====================
  Widget _buildSecurityView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Area
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Security Panel",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  "Authentication lock system & dynamic CCTV cameras",
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.35)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: securityArm ? Colors.redAccent.withOpacity(0.15) : Colors.greenAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: securityArm ? Colors.redAccent.withOpacity(0.3) : Colors.greenAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: securityArm ? Colors.redAccent : Colors.greenAccent, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    securityArm ? "SYSTEM ARMED" : "SYSTEM DISARMED",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: securityArm ? Colors.redAccent : Colors.greenAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2-Column Split
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Custom Keypad Lock (flex: 4)
            Expanded(
              flex: 4,
              child: GlassContainer(
                padding: const EdgeInsets.all(18),
                bgOpacity: 0.05,
                child: Column(
                  children: [
                    const Text("ACCESS PORT AUTHORIZATION", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
                    const SizedBox(height: 14),
                    // Virtual LCD Readout screen
                    GlassContainer(
                      bgOpacity: 0.1,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 16),
                          Text(
                            enteredPin.isEmpty ? "ENTER PIN" : "*" * enteredPin.length,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4),
                          ),
                          IconButton(
                            icon: const Icon(Icons.backspace_outlined, color: Colors.white38, size: 14),
                            onPressed: () {
                              if (enteredPin.isNotEmpty) {
                                setState(() => enteredPin = enteredPin.substring(0, enteredPin.length - 1));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid Numpad
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.4,
                      children: [
                        _buildKeypadButton("1"), _buildKeypadButton("2"), _buildKeypadButton("3"),
                        _buildKeypadButton("4"), _buildKeypadButton("5"), _buildKeypadButton("6"),
                        _buildKeypadButton("7"), _buildKeypadButton("8"), _buildKeypadButton("9"),
                        _buildKeypadButton("C", color: Colors.redAccent.withOpacity(0.15)),
                        _buildKeypadButton("0"),
                        _buildKeypadButton("✔", color: Colors.greenAccent.withOpacity(0.15), isConfirm: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Right Column: CCTV viewport (flex: 6)
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("LIVE CCTV SURVEILLANCE FEED", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
                      DropdownButton<String>(
                        value: activeCamera,
                        dropdownColor: const Color(0xFF101323),
                        style: const TextStyle(color: Color(0xFF8E99F3), fontSize: 10.5, fontWeight: FontWeight.bold),
                        underline: const SizedBox(),
                        items: ["Front Porch", "Backyard Deck", "Interior Hallway"]
                            .map((cam) => DropdownMenuItem(value: cam, child: Text(cam.toUpperCase())))
                            .toList(),
                        onChanged: (newCam) {
                          if (newCam != null) {
                            setState(() => activeCamera = newCam);
                            _logEvent("Swapped CCTV viewport feed to $newCam");
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GlassContainer(
                    height: 230,
                    bgOpacity: 0.1,
                    padding: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        // Background placeholder network image representing the feed
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              activeCamera == "Front Porch"
                                  ? "https://images.unsplash.com/photo-1558036117-15d82a90b9b1?auto=format&fit=crop&q=80&w=600"
                                  : activeCamera == "Backyard Deck"
                                      ? "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80&w=600"
                                      : "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&q=80&w=600",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Dark overlay
                        Positioned.fill(child: Container(color: Colors.black38)),
                        // Active Scanline glowing bar
                        const _CameraScanlineAnimation(),
                        // Text HUD Overlays
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text("REC • CAMERA - ${activeCamera.toUpperCase()}", style: const TextStyle(fontSize: 8.5, color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                        const Positioned(
                          top: 12,
                          right: 12,
                          child: Text("FPS: 30.0 • SUB: CH_1", style: TextStyle(fontSize: 8.5, color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            color: Colors.black54,
                            child: Text(
                              DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' '),
                              style: const TextStyle(fontSize: 8, color: Colors.white70, fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: 12,
                          right: 12,
                          child: Icon(Icons.rss_feed_rounded, color: Colors.greenAccent, size: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit, {Color? color, bool isConfirm = false}) {
    return InkWell(
      onTap: () {
        if (digit == "C") {
          setState(() => enteredPin = "");
        } else if (isConfirm) {
          _verifyPasscode();
        } else {
          if (enteredPin.length < 4) {
            setState(() => enteredPin += digit);
          }
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        bgOpacity: 0.05,
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color != null ? Colors.white : Colors.white60,
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
        _logEvent("Security panel authenticated successfully. System arm toggled.");
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(securityArm ? "System successfully armed." : "System successfully disarmed."),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => enteredPin = "");
      _logEvent("Security authentication FAILURE: Invalid pin entered.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Authentication Failed: Invalid security PIN."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==================== ANALYTICS VIEW (TABLET EXCLUSIVE) ====================
  Widget _buildAnalyticsView(double curTemp, double curHum) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Analytics Console",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  "Historical climate patterns & streaming event logs",
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.35)),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8E99F3)),
              onPressed: () {
                _logEvent("Manually refreshed sensor telemetry curves");
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Analytics synchronized with database.")));
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Historical trends (Full width)
        GlassContainer(
          height: 170,
          child: ClimateTrendsChart(
            dataPoints: tempHistory,
            lineColor: const Color(0xFFE57373),
            label: "COMPARATIVE TEMP TRENDS (24H)",
            suffix: "°C",
          ),
        ),
        const SizedBox(height: 20),

        // Scrolling logs list
        const Text("REAL-TIME SYSTEM DEPLOYMENT EVENTS", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
        const SizedBox(height: 10),
        GlassContainer(
          height: 180,
          bgOpacity: 0.05,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: systemLogs.length,
            separatorBuilder: (c, i) => const Divider(color: Colors.white10, height: 10),
            itemBuilder: (context, index) {
              return Text(
                systemLogs[index],
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', height: 1.4),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== SETTINGS VIEW (TABLET EXCLUSIVE) ====================
  Widget _buildSettingsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "System Settings",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
            ),
            const SizedBox(height: 2),
            Text(
              "Local node override configurations & firmware diagnostics",
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.35)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2-Column Split
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (flex: 1)
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("USER ACCOUNT PROFILE", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  GlassContainer(
                    bgOpacity: 0.05,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF8E99F3).withOpacity(0.2),
                              radius: 18,
                              child: const Icon(Icons.person_outline_rounded, color: Color(0xFF8E99F3), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    FirebaseAuth.instance.currentUser?.email ?? "admin@aminai.local",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const Text(
                                    "Registered Account Owner",
                                    style: TextStyle(fontSize: 9, color: Colors.white38),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 14),
                        const Text("ACCOUNT TOKEN (UID)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white30)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                FirebaseAuth.instance.currentUser?.uid ?? "unauthenticated_token",
                                style: const TextStyle(fontSize: 11.5, fontFamily: "monospace", color: Colors.white70, letterSpacing: -0.2),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5C6BC0).withOpacity(0.3),
                                side: const BorderSide(color: Color(0xFF8E99F3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onPressed: () {
                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                if (uid != null && uid.isNotEmpty) {
                                  Clipboard.setData(ClipboardData(text: uid));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Account Token (UID) copied to clipboard!"),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 11),
                              label: const Text("COPY", style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(0.2),
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                              },
                              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 11),
                              label: const Text("LOGOUT", style: TextStyle(fontSize: 9.5, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("LOCAL MULTICAST HOST CONFIG", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  GlassContainer(
                    bgOpacity: 0.05,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: mdnsHost,
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Color(0xFF8E99F3), size: 18),
                          onPressed: () {
                            _logEvent("mDNS local domain override successfully registered to $mdnsHost");
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("mDNS host override successfully set.")));
                          },
                        ),
                      ),
                      onChanged: (v) => mdnsHost = v,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("MCU OVER-THE-AIR DIAGNOSTICS", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  GlassContainer(
                    bgOpacity: 0.05,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Current: Firmware v1.0.4", style: TextStyle(fontSize: 11, color: Colors.white)),
                            SizedBox(height: 2),
                            Text("ESP32 Build Target: rev_C3", style: TextStyle(fontSize: 8.5, color: Colors.white38)),
                          ],
                        ),
                        isCheckingOTA
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8E99F3)))
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5C6BC0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  setState(() => isCheckingOTA = true);
                                  _logEvent("Initiated over-the-air firmware check with cloud depot");
                                  Future.delayed(const Duration(seconds: 2), () {
                                    if (mounted) {
                                      setState(() => isCheckingOTA = false);
                                      _logEvent("OTA update response: Firmware v1.0.4 is secure and up to date.");
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("System secure. Firmware is up to date.")),
                                      );
                                    }
                                  });
                                },
                                child: const Text("CHECK OTA", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // Right Column (flex: 1)
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("USER INTERFACE CONTRAST LEVEL", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  GlassContainer(
                    bgOpacity: 0.05,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      children: [
                        Slider(
                          value: uiContrast,
                          min: 0.8,
                          max: 1.2,
                          activeColor: const Color(0xFF8E99F3),
                          inactiveColor: Colors.white10,
                          onChanged: (val) {
                            setState(() => uiContrast = val);
                          },
                        ),
                        Text("Current Contrast Adjust: ${(uiContrast * 100).toInt()}%", style: const TextStyle(fontSize: 10, color: Colors.white54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("NVS FLASH CACHE RESETS", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  GlassContainer(
                    bgOpacity: 0.05,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Reset Local Hub Cache", style: TextStyle(fontSize: 11, color: Colors.white)),
                            SizedBox(height: 2),
                            Text("Will wipe mDNS states only", style: TextStyle(fontSize: 8.5, color: Colors.white38)),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.15),
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _showCacheResetConfirmation,
                          child: const Text("PURGE FLASH", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
            glowColor: Colors.redAccent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "CONFIRM CACHE PURGE",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Are you sure you want to purge your local node settings? This will revert mDNS host overrides and clear cached analytics logs.",
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
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() {
                          mdnsHost = "aminai-hub.local";
                          systemLogs = [
                            "[12:45:10] Firebase RTDB: Connected to Cloud Server Stream",
                            "[12:30:00] ESP32 Hub: State synchronized with Flash NVS",
                          ];
                          _logEvent("Wiped flash memory cache - Reinitialized system registries");
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Cache wiped. Reinitialized settings registers.")),
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

  // ==================== DIALOGS & POPUPS ====================
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
                    hintText: "e.g., Garage",
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

  void _showAddRuleDialog() {
    String triggerVal = "If Temperature > 28°C";
    String actionVal = "Turn ON Air Purifier";
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
                      "BUILD AUTOMATION RULE",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text("SELECT CONDITIONAL TRIGGER", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                      child: DropdownButton<String>(
                        value: triggerVal,
                        dropdownColor: const Color(0xFF101323),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        underline: const SizedBox(),
                        isExpanded: true,
                        items: ["If Temperature > 28°C", "If Humidity > 70%", "If Motion Detected", "If Sunset", "If SSID Scan Finished"]
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => triggerVal = v);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("SELECT DESIRED TARGET ACTION", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                      child: DropdownButton<String>(
                        value: actionVal,
                        dropdownColor: const Color(0xFF101323),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        underline: const SizedBox(),
                        isExpanded: true,
                        items: ["Turn ON Air Purifier", "Turn OFF Main Lights", "Trigger Alert Siren", "Arm Perimeter Sensors", "Toggle Physical MCU Relay"]
                            .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => actionVal = v);
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
                                "trigger": triggerVal,
                                "action": actionVal,
                                "enabled": "true",
                              });
                              _logEvent("Built automation rule: $triggerVal -> $actionVal");
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("CREATE RULE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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

  void _showAddDeviceDialog() {
    final nameController = TextEditingController();
    String selectedRoom = userRooms.first;
    bool isWired = false;
    int? selectedPort = 13; // default GPIO 13
    String selectedIcon = "lightbulb";
    String selectedGlow = "amber";
    
    // Upgraded device attributes
    String selectedDirection = "output"; // "output" or "input"
    String selectedValType = "binary"; // "binary", "dimmer", "analog_sensor"
    String selectedPinMode = "default"; // "default", "pullup", "pulldown"

    // Safe pin lists
    final List<int> reservedPins = [0, 1, 3, 4, 5, 12, 15];
    final List<int> inputOnlyPins = [34, 35, 36, 39];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Compute list of available ports based on direction
            final List<int> allAvailablePins = [2, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33, 34, 35, 36, 39];
            final List<int> availablePins = allAvailablePins.where((pin) {
              if (selectedDirection == "output" && inputOnlyPins.contains(pin)) {
                return false;
              }
              return true;
            }).toList();

            // Ensure selected port is in the available pins list
            if (!availablePins.contains(selectedPort)) {
              selectedPort = availablePins.first;
            }

            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              content: GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                bgOpacity: 0.12,
                borderOpacity: 0.15,
                glowColor: const Color(0xFF8E99F3),
                glowBlurRadius: 20.0,
                width: 420,
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
                          hintText: "e.g., Office Spotlight",
                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                          filled: true,
                          fillColor: Colors.black26,
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

                      // Room Dropdown (Dynamic)
                      const Text(
                        "ASSIGN ROOM LOCATION",
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: DropdownButton<String>(
                          value: selectedRoom,
                          dropdownColor: const Color(0xFF101323),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          underline: const SizedBox(),
                          isExpanded: true,
                          items: userRooms
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

                      if (isWired) ...[
                        // INTERFACE DIRECTION (Input vs Output)
                        const Text(
                          "INTERFACE DIRECTION",
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text("OUTPUT CONTROLLER", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                selected: selectedDirection == "output",
                                selectedColor: const Color(0xFF8E99F3).withOpacity(0.3),
                                backgroundColor: Colors.transparent,
                                labelStyle: TextStyle(color: selectedDirection == "output" ? Colors.white : Colors.white38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onSelected: (selected) {
                                  setDialogState(() {
                                    selectedDirection = "output";
                                    selectedValType = "binary"; // reset value type
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text("INPUT SENSOR", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                selected: selectedDirection == "input",
                                selectedColor: const Color(0xFFE57373).withOpacity(0.3),
                                backgroundColor: Colors.transparent,
                                labelStyle: TextStyle(color: selectedDirection == "input" ? Colors.white : Colors.white38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onSelected: (selected) {
                                  setDialogState(() {
                                    selectedDirection = "input";
                                    selectedValType = "binary"; // reset value type
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // CONTROL TYPE
                        const Text(
                          "CONTROL / VALUE TYPE",
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text("BINARY TOGGLE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                selected: selectedValType == "binary",
                                selectedColor: const Color(0xFF5C6BC0).withOpacity(0.3),
                                backgroundColor: Colors.transparent,
                                labelStyle: TextStyle(color: selectedValType == "binary" ? Colors.white : Colors.white38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onSelected: (selected) {
                                  setDialogState(() => selectedValType = "binary");
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (selectedDirection == "output")
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text("RANGE DIMMER", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  selected: selectedValType == "dimmer",
                                  selectedColor: const Color(0xFF5C6BC0).withOpacity(0.3),
                                  backgroundColor: Colors.transparent,
                                  labelStyle: TextStyle(color: selectedValType == "dimmer" ? Colors.white : Colors.white38),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  onSelected: (selected) {
                                    setDialogState(() => selectedValType = "dimmer");
                                  },
                                ),
                              ),
                            if (selectedDirection == "input")
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text("ANALOG SENSOR", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  selected: selectedValType == "analog_sensor",
                                  selectedColor: const Color(0xFF5C6BC0).withOpacity(0.3),
                                  backgroundColor: Colors.transparent,
                                  labelStyle: TextStyle(color: selectedValType == "analog_sensor" ? Colors.white : Colors.white38),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  onSelected: (selected) {
                                    setDialogState(() => selectedValType = "analog_sensor");
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // PIN CONFIG MODE (Pullup / Pulldown) - only shown for inputs
                        if (selectedDirection == "input") ...[
                          const Text(
                            "PIN INTERNALS (PULL RESISTOR)",
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: DropdownButton<String>(
                              value: selectedPinMode,
                              dropdownColor: const Color(0xFF101323),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              underline: const SizedBox(),
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: "default", child: Text("Default Floating (INPUT)")),
                                DropdownMenuItem(value: "pullup", child: Text("Internal Pull-Up (INPUT_PULLUP)")),
                                DropdownMenuItem(value: "pulldown", child: Text("Internal Pull-Down (INPUT_PULLDOWN)")),
                              ],
                              onChanged: (v) {
                                if (v != null) setDialogState(() => selectedPinMode = v);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Wired Port Selector
                        const Text(
                          "SELECT DIRECT MCU PORT (GPIO PIN)",
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: DropdownButton<int>(
                            value: selectedPort,
                            dropdownColor: const Color(0xFF101323),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            underline: const SizedBox(),
                            isExpanded: true,
                            items: availablePins
                                .map((pin) => DropdownMenuItem(
                                      value: pin,
                                      child: Text(
                                        "GPIO Pin $pin ${reservedPins.contains(pin) ? '(RESERVED)' : ''}",
                                        style: TextStyle(
                                          color: reservedPins.contains(pin) ? const Color(0xFFE57373) : Colors.white,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedPort = v);
                            },
                          ),
                        ),
                        
                        // Show Warning if a reserved pin is chosen
                        if (reservedPins.contains(selectedPort)) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE57373), size: 12),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  "WARNING: Pin $selectedPort is a system boot/DHT pin. Assigning it can cause boot-loops.",
                                  style: const TextStyle(color: Color(0xFFE57373), fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
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

                          // Validation for duplicate pin
                          if (isWired && selectedPort != null) {
                            final bool pinExists = dynamicDevices.any((d) => d["isWired"] == true && d["port"] == selectedPort);
                            if (pinExists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Collision! GPIO Pin $selectedPort is already assigned to another device."),
                                  backgroundColor: const Color(0xFFE57373),
                                ),
                              );
                              return;
                            }
                          }
                          
                          final String newId = "device_${DateTime.now().millisecondsSinceEpoch}";
                          final Map<String, dynamic> newDevice = {
                            "id": newId,
                            "name": nameController.text.trim(),
                            "room": selectedRoom,
                            "isWired": isWired,
                            "port": isWired ? selectedPort : null,
                            "direction": isWired ? selectedDirection : "output",
                            "valueType": isWired ? selectedValType : "binary",
                            "pinMode": isWired ? selectedPinMode : "default",
                            "state": false,
                            "value": selectedValType == "dimmer" ? 0 : false,
                            "icon": selectedIcon,
                            "glowColor": selectedGlow,
                          };

                          _networkService.addDevice(newDevice);
                          Navigator.pop(context);
                          _logEvent("Registered new device: '${nameController.text.trim()}' in $selectedRoom");
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Registered '${nameController.text.trim()}' successfully."),
                              backgroundColor: const Color(0xFF81C784),
                            ),
                          );
                        },
                        child: const Text("PROVISION HARDWARE NODE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
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
    final bool active = current == key;
    return InkWell(
      onTap: () => setDialogState(() => onSelected(key)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: active ? const Color(0xFF5C6BC0).withOpacity(0.2) : Colors.black12, borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? const Color(0xFF8E99F3) : Colors.white.withOpacity(0.04))),
        child: Icon(icon, color: active ? const Color(0xFF8E99F3) : Colors.white38, size: 20),
      ),
    );
  }

  Widget _buildColorChoice(StateSetter setDialogState, String key, Color color, String current, ValueChanged<String> onSelected) {
    final bool active = current == key;
    return InkWell(
      onTap: () => setDialogState(() => onSelected(key)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: active ? color.withOpacity(0.15) : Colors.black12, borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? color : Colors.white.withOpacity(0.04))),
        child: Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }

  void _showDeleteConfirmation(String id, String name) {
    if (id == "device_lights") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot delete core system relay.")));
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
            glowColor: Colors.redAccent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("DELETE DEVICE REGISTRY", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Text("Are you sure you want to completely deregister and wipe '$name' from your Smart Home local database?", style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                        _networkService.deleteDevice(id);
                        Navigator.pop(context);
                        _logEvent("Deregistered hardware node: $name");
                      },
                      child: const Text("DELETE NODE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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

  // ==================== BASE REUSABLE LAYOUT SHARDS ====================
  Widget _buildCompactRailItem(IconData icon, String section, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () async {
          if (section == "Logout") {
            await FirebaseAuth.instance.signOut();
          } else {
            setState(() {
              selectedSection = section;
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: active ? Colors.white.withOpacity(0.08) : Colors.transparent,
            border: active ? Border.all(color: Colors.white.withOpacity(0.12), width: 1.0) : null,
          ),
          child: Icon(
            icon,
            color: active ? const Color(0xFF8E99F3) : Colors.white54,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomFilters() {
    final List<String> filterList = ["All Rooms", ...userRooms];
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filterList.length,
        itemBuilder: (context, index) {
          final String rName = filterList[index];
          final bool active = activeRoom == rName;
          return Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(rName.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              selected: active,
              selectedColor: const Color(0xFF5C6BC0).withOpacity(0.4),
              backgroundColor: Colors.white.withOpacity(0.03),
              labelStyle: TextStyle(color: active ? Colors.white : Colors.white38),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: active ? const Color(0xFF8E99F3).withOpacity(0.4) : Colors.white.withOpacity(0.03), width: 1),
              ),
              onSelected: (selected) {
                if (selected) setState(() => activeRoom = rName);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusFilters() {
    final int allCount = dynamicDevices.length + 1;
    final int onlineCount = dynamicDevices.where((d) => d["status"] == "online" || d["status"] == null).length + 1;
    final int offlineCount = dynamicDevices.where((d) => d["status"] == "offline").length;
    final int faultyCount = dynamicDevices.where((d) => d["status"] == "faulty").length;

    final List<Map<String, dynamic>> filters = [
      {"label": "All Nodes", "filter": "All", "count": allCount, "color": Colors.white},
      {"label": "Online", "filter": "Online", "count": onlineCount, "color": Colors.greenAccent},
      {"label": "Offline", "filter": "Offline", "count": offlineCount, "color": Colors.white54},
      {"label": "Faulty", "filter": "Faulty", "count": faultyCount, "color": Colors.redAccent},
    ];

    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final bool isSelected = activeStatusFilter == filter["filter"];
          final Color badgeColor = filter["color"];

          return Container(
            margin: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => setState(() => activeStatusFilter = filter["filter"]),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected ? badgeColor.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: isSelected ? badgeColor : Colors.white.withOpacity(0.08),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filter["filter"] != "All") ...[
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      "${filter["label"]} (${filter["count"]})",
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? badgeColor : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case "offline":
        color = Colors.white38;
        break;
      case "faulty":
        color = Colors.redAccent;
        break;
      default:
        color = Colors.greenAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            status.toUpperCase(),
            style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      bgOpacity: 0.05,
      child: const Row(
        children: [
          Icon(Icons.wb_cloudy_rounded, color: Color(0xFF64B5F6), size: 16),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("CLOUDY • OAKLAND", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white54)),
              Text("18.5°C • NW 14MPH", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard({
    required String id,
    required IconData icon,
    required String name,
    required String room,
    required bool isActive,
    required ValueChanged<bool> onChanged,
    required Color glowColor,
    required bool isWired,
    required int? port,
    String status = "online",
    String direction = "output",
    String valueType = "binary",
    dynamic value,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.18),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ]
            : [],
      ),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        bgOpacity: isActive ? 0.08 : 0.04,
        glowColor: isActive ? glowColor : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isActive ? glowColor.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? glowColor : Colors.white30,
                    size: 18,
                  ),
                ),
                
                // Render correct control/widget based on direction & valueType
                if (direction == "input") ...[
                  // Read-only indicator badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? glowColor.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isActive ? glowColor.withOpacity(0.3) : Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? glowColor : Colors.white30,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          valueType == "analog_sensor"
                              ? "${value ?? 0}"
                              : (isActive ? "HIGH" : "LOW"),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isActive ? Colors.white : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (valueType == "dimmer") ...[
                  Switch(
                    value: isActive,
                    activeColor: glowColor,
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.white12,
                    onChanged: onChanged,
                  ),
                ] else ...[
                  Switch(
                    value: isActive,
                    activeColor: glowColor,
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.white12,
                    onChanged: onChanged,
                  ),
                ],
              ],
            ),
            const Spacer(),
            if (direction == "output" && valueType == "dimmer" && isActive) ...[
              // Sleek inline slider for range-dimmer
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        activeTrackColor: glowColor,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      ),
                      child: Slider(
                        value: (value is num) ? value.toDouble() : 0.0,
                        min: 0,
                        max: 100,
                        onChanged: (newVal) {
                          _networkService.updateDeviceValue(id, newVal.round());
                        },
                      ),
                    ),
                  ),
                  Text(
                    "${value ?? 0}%",
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: glowColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      room.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _buildStatusBadge(status),
                  ],
                ),
                Text(
                  isWired ? "PIN $port" : "WIRELESS",
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: isWired ? const Color(0xFF8E99F3).withOpacity(0.6) : Colors.tealAccent.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildACCard() {
    return GlassContainer(
      glowColor: acState ? Colors.tealAccent : null,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: (acState ? Colors.tealAccent : Colors.white).withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.air_rounded, color: Colors.tealAccent, size: 18),
              ),
              Switch(value: acState, activeColor: Colors.tealAccent, onChanged: (v) => setState(() => acState = v)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CLIMATE AC", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
                  const SizedBox(height: 2),
                  Text("${acTargetTemp.toStringAsFixed(1)}°C", style: const TextStyle(fontSize: 9, color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              if (acState)
                Row(
                  children: [
                    _buildTempButton(Icons.remove, () => setState(() => acTargetTemp -= 0.5)),
                    const SizedBox(width: 4),
                    _buildTempButton(Icons.add, () => setState(() => acTargetTemp += 0.5)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, color: Colors.white70, size: 12),
      ),
    );
  }

  Widget _buildCompactSceneButton(String text, IconData icon, String sceneName) {
    return InkWell(
      onTap: () => _triggerScene(sceneName),
      borderRadius: BorderRadius.circular(10),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        bgOpacity: 0.05,
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF8E99F3), size: 16),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.white38)),
        Text(value, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white70, fontFamily: 'monospace')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double curTemp = temperature ?? 24.5;
    final double curHum = humidity ?? 48.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF090A0F),
              Color(0xFF101323),
              Color(0xFF1B1E38),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // ================== COLUMN 1: LEFT COMPACT SIDEBAR RAIL ==================
            Container(
              width: 76,
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                border: Border(
                  right: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.2),
                ),
              ),
              child: Column(
                children: [
                  // Brand Logo Compact
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6BC0).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.blur_on_rounded, color: Color(0xFF8E99F3), size: 24),
                  ),
                  const SizedBox(height: 40),
                  // Icons only Navigation Rail
                  _buildCompactRailItem(Icons.dashboard_rounded, "Dashboard", active: selectedSection == "Dashboard"),
                  _buildCompactRailItem(Icons.meeting_room_rounded, "Rooms", active: selectedSection == "Rooms"),
                  _buildCompactRailItem(Icons.devices_other_rounded, "Devices", active: selectedSection == "Devices"),
                  _buildCompactRailItem(Icons.offline_bolt_rounded, "Automations", active: selectedSection == "Automations"),
                  _buildCompactRailItem(Icons.security_rounded, "Security Panel", active: selectedSection == "Security Panel"),
                  _buildCompactRailItem(Icons.bar_chart_rounded, "Analytics", active: selectedSection == "Analytics"),
                  _buildCompactRailItem(Icons.settings_rounded, "Settings", active: selectedSection == "Settings"),
                  _buildCompactRailItem(Icons.logout_rounded, "Logout"),
                  const Spacer(),
                  // Active user indicator
                  CircleAvatar(
                    backgroundColor: const Color(0xFF5C6BC0),
                    radius: 14,
                    child: const Icon(Icons.person, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),

            // ================== COLUMNS 2 & 3: MAIN TWO-COLUMN CONTENT ==================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                child: _buildMainContent(curTemp, curHum),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          top: _controller.value * 230,
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
