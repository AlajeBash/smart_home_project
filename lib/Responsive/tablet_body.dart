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

  double? temperature;
  double? humidity;
  bool relayState = false;

  // Mock devices states
  bool acState = false;
  double acTargetTemp = 24.0;
  bool purifierState = true;
  bool securityArm = true;
  bool blindsState = false;

  // Dynamic registered devices list
  List<Map<String, dynamic>> dynamicDevices = [];
  StreamSubscription? _devicesSub;

  // Active room filter
  String activeRoom = "All Rooms";

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
                  _buildCompactRailItem(Icons.dashboard_rounded, active: true),
                  _buildCompactRailItem(Icons.meeting_room_rounded),
                  _buildCompactRailItem(Icons.offline_bolt_rounded),
                  _buildCompactRailItem(Icons.security_rounded),
                  _buildCompactRailItem(Icons.bar_chart_rounded),
                  _buildCompactRailItem(Icons.settings_rounded),
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
                child: Column(
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
                              "Bash Smart Hub",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Secure Local Tablet Interface",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.35),
                              ),
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
                        // LEFT GRID: Telemetry & Devices
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
                                          const Text(
                                            "Temp Node",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70),
                                          ),
                                          const SizedBox(height: 10),
                                          TemperatureGauge(temperature: curTemp),
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
                                          const Text(
                                            "Humidity Node",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70),
                                          ),
                                          const SizedBox(height: 10),
                                          HumidityGauge(humidity: curHum),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Devices Grid (2 columns)
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
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        // RIGHT COLUMN: Analytics, Scenes & Diagnostics
                        Expanded(
                          flex: 9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Trends stacked
                              GlassContainer(
                                height: 180,
                                child: ClimateTrendsChart(
                                  dataPoints: tempHistory,
                                  lineColor: const Color(0xFFE57373),
                                  label: "TEMPERATURE HISTORY (24H)",
                                  suffix: "°C",
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Scenes row
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

                              // Diagnostic Panel compact
                              const Text(
                                "HARDWARE STATUS",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white30, letterSpacing: 1.0),
                              ),
                              const SizedBox(height: 10),
                              GlassContainer(
                                bgOpacity: 0.05,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Column(
                                  children: [
                                    _buildDiagRow("IP ADDRESS", "192.168.1.145"),
                                    const Divider(color: Colors.white10, height: 12),
                                    _buildDiagRow("WI-FI RSSI", "-48 dBm (Excellent)"),
                                    const Divider(color: Colors.white10, height: 12),
                                    _buildDiagRow("HW UPTIME", "4d 18h 32m"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact Rail Item builder
  Widget _buildCompactRailItem(IconData icon, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {},
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

  // Room filters selector
  Widget _buildRoomFilters() {
    final List<String> rooms = ["All Rooms", "Living Room", "Bedroom", "Kitchen", "Smart Office"];
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final bool isSelected = activeRoom == rooms[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
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
                      fontSize: 10.5,
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

  // Simulated weather panel
  Widget _buildWeatherWidget() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 12,
      bgOpacity: 0.08,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 18),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "31°C • Sunny",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                "NW 12km/h",
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w400, color: Colors.white38),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.all(10),
      glowColor: isActive ? glowColor : null,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? glowColor.withOpacity(0.12) : Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? glowColor : Colors.white24,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(
                      room,
                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w500, color: Colors.white38),
                    ),
                    if (isWired && port != null) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E99F3).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF8E99F3).withOpacity(0.3), width: 0.5),
                        ),
                        child: Text(
                          "PIN $port",
                          style: const TextStyle(fontSize: 7.0, fontWeight: FontWeight.bold, color: Color(0xFF8E99F3)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.70,
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

  // A/C controller Card
  Widget _buildACCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      glowColor: acState ? Colors.cyan : null,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: acState ? Colors.cyan.withOpacity(0.12) : Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.ac_unit_rounded,
              color: acState ? Colors.cyanAccent : Colors.white24,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Smart A/C",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  acState ? "Cooling • ${acTargetTemp.toStringAsFixed(0)}°" : "AC Standby",
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: acState ? Colors.cyanAccent : Colors.white38,
                  ),
                ),
                if (acState) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _buildTempButton(Icons.remove, () {
                        if (acTargetTemp > 16) setState(() => acTargetTemp--);
                      }),
                      const SizedBox(width: 6),
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
            scale: 0.70,
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
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white70, size: 8),
      ),
    );
  }

  // Scenes compact triggers
  Widget _buildCompactSceneButton(String text, IconData icon, String sceneName) {
    return InkWell(
      onTap: () => _triggerScene(sceneName),
      borderRadius: BorderRadius.circular(10),
      child: GlassContainer(
        bgOpacity: 0.08,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF8E99F3), size: 16),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // Diagnostics Row
  Widget _buildDiagRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.white38)),
        Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white70)),
      ],
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
}

