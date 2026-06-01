import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_home_front_end/exports.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key});

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

class _DesktopBodyState extends State<DesktopBody> {
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
          
          // Append new real-time value to history and trim to keep fixed length
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
              Color(0xFF1A1D36),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // ================== COLUMN 1: LEFT SIDEBAR ==================
            Container(
              width: 260,
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                border: Border(
                  right: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Logo
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C6BC0).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5C6BC0).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.blur_on_rounded, color: Color(0xFF8E99F3), size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "AURA",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            "SMART HOME",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white38,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Navigation Items
                  _buildSidebarItem(Icons.dashboard_rounded, "Dashboard", active: true),
                  _buildSidebarItem(Icons.meeting_room_rounded, "Rooms"),
                  _buildSidebarItem(Icons.offline_bolt_rounded, "Automations"),
                  _buildSidebarItem(Icons.security_rounded, "Security Panel"),
                  _buildSidebarItem(Icons.bar_chart_rounded, "Analytics"),
                  _buildSidebarItem(Icons.settings_rounded, "Settings"),
                  const Spacer(),
                  // Active Profile Card
                  GlassContainer(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 14,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF5C6BC0),
                          radius: 18,
                          child: const Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Alaje Bash",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text(
                              "System Admin",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white38),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.emeraldAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.emerald, blurRadius: 4, spreadRadius: 1),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================== COLUMN 2: CENTRAL MAIN CONTENT ==================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Greeting Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Welcome Home, Bash",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 13, color: Colors.white.withOpacity(0.4)),
                                const SizedBox(width: 4),
                                Text(
                                  "Central Command Node • Secure System Online",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Weather Widget
                        _buildWeatherWidget(),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Room Selection Bar
                    _buildRoomFilters(),
                    const SizedBox(height: 25),

                    // Live Gauges Grid Panel (Side-by-side)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GlassContainer(
                            glowColor: const Color(0xFFE57373),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.thermostat, color: Color(0xFFE57373), size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          "Temperature Node",
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      relayState ? "HEATING RUNNING" : "STANDBY",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: relayState ? const Color(0xFF81C784) : Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white10, height: 20),
                                TemperatureGauge(temperature: curTemp),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: GlassContainer(
                            glowColor: const Color(0xFF64B5F6),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.water_drop, color: Color(0xFF64B5F6), size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          "Humidity Node",
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      "OPTIMAL CLIMATE",
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF81C784)),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white10, height: 20),
                                HumidityGauge(humidity: curHum),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Interactive Trends Chart
                    GlassContainer(
                      height: 220,
                      child: Row(
                        children: [
                          Expanded(
                            child: ClimateTrendsChart(
                              dataPoints: tempHistory,
                              lineColor: const Color(0xFFE57373),
                              label: "TEMPERATURE TELEMETRY (24H TREND)",
                              suffix: "°C",
                            ),
                          ),
                          const VerticalDivider(color: Colors.white10, width: 40),
                          Expanded(
                            child: ClimateTrendsChart(
                              dataPoints: humHistory,
                              lineColor: const Color(0xFF64B5F6),
                              label: "HUMIDITY TELEMETRY (24H TREND)",
                              suffix: "%",
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Smart Devices Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "ACTIVE SMART DEVICES",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white54,
                            letterSpacing: 1.0,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF8E99F3), size: 22),
                          onPressed: _showAddDeviceDialog,
                          tooltip: "Register New Hardware Device",
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Devices responsive grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
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
            ),

            // ================== COLUMN 3: RIGHT PANEL ==================
            Container(
              width: 330,
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "QUICK AUTOMATED SCENES",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white54,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Scenes
                  _buildSceneButton("Away Mode", Icons.exit_to_app_rounded, "Away", subtitle: "Turn off devices, arm security"),
                  _buildSceneButton("Movie Night", Icons.movie_filter_rounded, "Movie", subtitle: "Dim lights, close blinds, cold climate"),
                  _buildSceneButton("Sleep Mode", Icons.bedtime_rounded, "Sleep", subtitle: "Turn off lights, eco climate"),
                  _buildSceneButton("Eco Saving", Icons.eco_rounded, "Eco", subtitle: "Minimize passive power draws"),
                  
                  const SizedBox(height: 35),
                  const Text(
                    "SYSTEM HEALTH & STATUS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white54,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Active warnings or alerts
                  GlassContainer(
                    bgOpacity: 0.08,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildHealthRow(Icons.check_circle, "Realtime Database", "Active", Colors.emerald),
                        const SizedBox(height: 10),
                        _buildHealthRow(Icons.check_circle, "ESP32 Hardware Module", "Connected", Colors.emerald),
                        const SizedBox(height: 10),
                        _buildHealthRow(Icons.warning, "CO2 Purifier Filter", "Change Soon (15%)", Colors.orange),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "HARDWARE DIAGNOSTICS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white54,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Network/Uptime Diagnostics
                  GlassContainer(
                    bgOpacity: 0.04,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDiagRow("IP ADDRESS", "192.168.1.145"),
                        _buildDiagRow("WI-FI STRENGTH", "-48 dBm (Strong)"),
                        _buildDiagRow("FIRMWARE VER", "AURA.ESP32.v1.0.8"),
                        _buildDiagRow("SYSTEM UPTIME", "4d 18h 32m"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper builder for sidebar item
  Widget _buildSidebarItem(IconData icon, String title, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: active ? Colors.white.withOpacity(0.08) : Colors.transparent,
              border: active
                  ? Border.all(color: Colors.white.withOpacity(0.12), width: 1.0)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: active ? const Color(0xFF8E99F3) : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Room filters selector
  Widget _buildRoomFilters() {
    final List<String> rooms = ["All Rooms", "Living Room", "Bedroom", "Kitchen", "Smart Office", "Security"];
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final bool isSelected = activeRoom == rooms[index];
          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => activeRoom = rooms[index]),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(color: Colors.white.withOpacity(0.25), blurRadius: 10, spreadRadius: -2),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    rooms[index],
                    style: TextStyle(
                      fontSize: 11.5,
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

  // Dynamic simulated weather panel
  Widget _buildWeatherWidget() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      borderRadius: 14,
      bgOpacity: 0.08,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 22),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "31°C • Outdoor Sunny",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                "Wind: NW 12km/h • Hum: 34%",
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w500, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // General Interactive Device Card Builder
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
      padding: const EdgeInsets.all(12),
      glowColor: isActive ? glowColor : null,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? glowColor.withOpacity(0.15) : Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? glowColor.withOpacity(0.3) : Colors.white10,
                width: 1.0,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? glowColor : Colors.white24,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      room,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white38),
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
            scale: 0.75,
            child: Switch(
              value: isActive,
              activeColor: glowColor,
              activeTrackColor: glowColor.withOpacity(0.24),
              inactiveThumbColor: Colors.white30,
              inactiveTrackColor: Colors.black26,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // Custom controller Card specifically for Smart A/C
  Widget _buildACCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(10),
      glowColor: acState ? Colors.cyan : null,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: acState ? Colors.cyan.withOpacity(0.15) : Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.ac_unit_rounded,
              color: acState ? Colors.cyanAccent : Colors.white24,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Smart A/C",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  acState ? "Cooling • ${acTargetTemp.toStringAsFixed(0)}°C" : "AC Standby",
                  style: TextStyle(
                    fontSize: 9,
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
            scale: 0.75,
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
        child: Icon(icon, color: Colors.white70, size: 10),
      ),
    );
  }

  // Scene triggers helper
  Widget _buildSceneButton(String text, IconData icon, String sceneName, {required String subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _triggerScene(sceneName),
        borderRadius: BorderRadius.circular(12),
        child: GlassContainer(
          bgOpacity: 0.06,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF8E99F3), size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w400, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_right, color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Diagnostics Health Rows
  Widget _buildHealthRow(IconData icon, String name, String status, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 10),
        Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70)),
        const Spacer(),
        Text(status, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // Diagnostics key-value Rows
  Widget _buildDiagRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white38)),
          Text(value, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white70)),
        ],
      ),
    );
  }

  // Dynamic Add Device Dialog
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

                      // Room Dropdown
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
                          items: ["Living Room", "Bedroom", "Kitchen", "Smart Office", "Security"]
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
