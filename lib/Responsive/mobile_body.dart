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
                child: SingleChildScrollView(
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
                ),
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
            _buildDrawerTile(Icons.dashboard_rounded, "Dashboard", active: true),
            _buildDrawerTile(Icons.meeting_room_rounded, "Rooms"),
            _buildDrawerTile(Icons.offline_bolt_rounded, "Automations"),
            _buildDrawerTile(Icons.security_rounded, "Security Panel"),
            _buildDrawerTile(Icons.bar_chart_rounded, "Analytics"),
            _buildDrawerTile(Icons.settings_rounded, "Settings"),
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

  Widget _buildDrawerTile(IconData icon, String title, {bool active = false}) {
    return ListTile(
      leading: Icon(icon, color: active ? const Color(0xFF8E99F3) : Colors.white54, size: 20),
      title: Text(
        title,
        style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? Colors.white : Colors.white70),
      ),
      selected: active,
      onTap: () => Navigator.pop(context),
    );
  }

  // Room Filters
  Widget _buildRoomFilters() {
    final List<String> rooms = ["All Rooms", "Living Room", "Bedroom", "Kitchen", "Office"];
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