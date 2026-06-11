import 'package:smart_home_front_end/exports.dart';

class AdminDashboard extends StatefulWidget {
  final NetworkService? networkService;

  const AdminDashboard({
    super.key,
    this.networkService,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final NetworkService _networkService;
  int _activeTab = 0; // 0 = Users, 1 = Devices, 2 = Logs
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _networkService = widget.networkService ?? NetworkService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF090A0F),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Navigation Tabs
          _buildHeader(),
          
          // Tab Content Detail
          Expanded(
            child: _buildActiveTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Color(0xFF8E99F3),
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "ADMIN CONSOLE",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Manage multi-tenant users, active nodes, and global operations",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              // Search Input
              if (_activeTab != 2) _buildSearchBar(),
            ],
          ),
          const SizedBox(height: 24),
          // Custom Tab Row
          Row(
            children: [
              _buildTabButton(0, "Users Manager", Icons.people_alt_rounded),
              const SizedBox(width: 12),
              _buildTabButton(1, "Devices Directory", Icons.developer_board_rounded),
              const SizedBox(width: 12),
              _buildTabButton(2, "Global Logs", Icons.history_edu_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 280,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: _activeTab == 0 ? "Search users by email..." : "Search devices by name/room...",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.4), size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                  child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.4), size: 16),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildTabButton(int tabIndex, String label, IconData icon) {
    final bool isActive = _activeTab == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabIndex;
          _searchQuery = "";
          _searchController.clear();
        });
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        bgOpacity: isActive ? 0.12 : 0.03,
        borderOpacity: isActive ? 0.25 : 0.06,
        borderRadius: 12,
        glowColor: isActive ? const Color(0xFF8E99F3) : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF8E99F3) : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildUsersTab();
      case 1:
        return _buildDevicesTab();
      case 2:
        return _buildLogsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ================= USERS TAB =================
  Widget _buildUsersTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _networkService.listenToAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E99F3)),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error fetching user data: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)),
          );
        }

        final users = snapshot.data ?? [];
        final filteredUsers = users.where((u) {
          final email = u["email"].toString().toLowerCase();
          final name = u["displayName"].toString().toLowerCase();
          return email.contains(_searchQuery) || name.contains(_searchQuery);
        }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, color: Colors.white24, size: 48),
                const SizedBox(height: 12),
                Text(
                  "No users found matching query",
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildUserExpansionCard(user),
            );
          },
        );
      },
    );
  }

  Widget _buildUserExpansionCard(Map<String, dynamic> user) {
    final String uid = user["uid"] ?? "";
    final String email = user["email"] ?? "";
    final String role = user["role"] ?? "user";
    final String displayName = user["displayName"] ?? "";
    final int createdAt = user["createdAt"] ?? 0;
    
    final createdDateStr = createdAt > 0 
        ? DateTime.fromMillisecondsSinceEpoch(createdAt).toLocal().toString().split('.').first 
        : "Unknown date";

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        bgOpacity: 0.04,
        borderOpacity: 0.08,
        borderRadius: 14,
        child: ExpansionTile(
          iconColor: const Color(0xFF8E99F3),
          collapsedIconColor: Colors.white38,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: role == "admin" ? const Color(0xFF8E99F3).withOpacity(0.15) : Colors.white.withOpacity(0.04),
                child: Icon(
                  role == "admin" ? Icons.security_rounded : Icons.person_rounded,
                  color: role == "admin" ? const Color(0xFF8E99F3) : Colors.white70,
                  size: 16,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              // Role Badge Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: role == "admin" ? const Color(0xFF8E99F3).withOpacity(0.12) : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: role == "admin" ? const Color(0xFF8E99F3).withOpacity(0.2) : Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: role == "admin" ? const Color(0xFF8E99F3) : Colors.white60,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 50, top: 4),
            child: Text(
              "Account ID: $uid  •  Created: $createdDateStr",
              style: TextStyle(
                fontSize: 9,
                color: Colors.white38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Administrative Actions",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white70),
                      ),
                      Row(
                        children: [
                          const Text("Role Toggle: ", style: TextStyle(fontSize: 11, color: Colors.white38)),
                          const SizedBox(width: 8),
                          _buildRoleDropdown(uid, role),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "User Household Devices",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white38, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  _buildUserDevicesView(uid),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDropdown(String targetUid, String currentRole) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButton<String>(
        value: currentRole,
        dropdownColor: const Color(0xFF0F111A),
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54, size: 18),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
        onChanged: (String? newRole) {
          if (newRole != null && newRole != currentRole) {
            _networkService.updateUserRole(targetUid, newRole);
          }
        },
        items: const [
          DropdownMenuItem(value: "user", child: Text("USER")),
          DropdownMenuItem(value: "admin", child: Text("ADMIN")),
        ],
      ),
    );
  }

  Widget _buildUserDevicesView(String userUid) {
    // We stream all devices globally and filter down to the active user's sub-devices
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _networkService.listenToGlobalDevices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final allDevices = snapshot.data ?? [];
        final userDevices = allDevices.where((d) => d["userUid"] == userUid).toList();

        if (userDevices.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text(
              "No physical smart-home hardware registered for this household.",
              style: TextStyle(fontSize: 11, color: Colors.white38, fontStyle: FontStyle.italic),
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: userDevices.map((dev) {
            return GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              borderRadius: 8,
              bgOpacity: 0.05,
              borderOpacity: 0.08,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    dev["icon"] == "lightbulb" ? Icons.lightbulb_rounded : Icons.air_rounded,
                    color: dev["state"] == true ? const Color(0xFF8E99F3) : Colors.white38,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${dev['name']} (${dev['room']})",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dev["status"] == "online" ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= DEVICES TAB =================
  Widget _buildDevicesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _networkService.listenToGlobalDevices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E99F3)),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error fetching devices: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)),
          );
        }

        final devices = snapshot.data ?? [];
        final filteredDevices = devices.where((d) {
          final name = d["name"].toString().toLowerCase();
          final room = d["room"].toString().toLowerCase();
          final email = d["userEmail"].toString().toLowerCase();
          return name.contains(_searchQuery) || room.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();

        if (filteredDevices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.developer_board_off_rounded, color: Colors.white24, size: 48),
                const SizedBox(height: 12),
                Text("No dynamic devices found matching query", style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: filteredDevices.length,
          itemBuilder: (context, index) {
            final dev = filteredDevices[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDeviceAdminCard(dev),
            );
          },
        );
      },
    );
  }

  Widget _buildDeviceAdminCard(Map<String, dynamic> dev) {
    final String name = dev["name"] ?? "";
    final String room = dev["room"] ?? "";
    final String userUid = dev["userUid"] ?? "";
    final String userEmail = dev["userEmail"] ?? "";
    final int? port = dev["port"];
    final bool isWired = dev["isWired"] ?? false;
    final String dir = dev["direction"] ?? "output";
    final String valType = dev["valueType"] ?? "binary";

    return StreamBuilder<Map<String, dynamic>>(
      stream: _networkService.listenToUserDiagnostics(userUid),
      builder: (context, diagSnapshot) {
        final diag = diagSnapshot.data ?? {
          "online": false,
          "ip": "0.0.0.0",
          "rssi": -100,
          "free_heap": 0,
          "uptime": "Offline",
        };
        final bool isOnline = diag["online"] ?? false;

        return GlassContainer(
          padding: const EdgeInsets.all(16),
          bgOpacity: 0.04,
          borderOpacity: 0.08,
          borderRadius: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: info & online indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C6BC0).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          dev["icon"] == "lightbulb" ? Icons.lightbulb_rounded : Icons.air_rounded,
                          color: const Color(0xFF8E99F3),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          Text(
                            "Room: $room  •  Account: $userEmail",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.4)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOnline ? Colors.greenAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? Colors.greenAccent : Colors.redAccent,
                            boxShadow: isOnline ? [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ] : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? "ONLINE" : "OFFLINE",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isOnline ? Colors.greenAccent : Colors.redAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withOpacity(0.05)),
              const SizedBox(height: 12),
              // Grid metrics
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool useCompactGrid = constraints.maxWidth < 600;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: useCompactGrid ? 2 : 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: useCompactGrid ? 2.5 : 2.2,
                    children: [
                      _buildMiniMetric("IP ADDRESS", isOnline ? diag["ip"] : "0.0.0.0", Icons.lan_rounded),
                      _buildMiniMetric("MCU UPTIME", isOnline ? diag["uptime"] : "Offline", Icons.av_timer_rounded),
                      _buildMiniMetric("RSSI (SIGNAL)", isOnline ? "${diag["rssi"]} dBm" : "Disconnected", Icons.wifi_tethering_rounded),
                      _buildMiniMetric("FREE HEAP", isOnline ? "${(diag["free_heap"] / 1024).round()} KB" : "0 KB", Icons.memory_rounded),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              // Bottom configurations & buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildPinBadge(isWired, port),
                      const SizedBox(width: 8),
                      _buildDirectionBadge(dir, valType),
                    ],
                  ),
                  if (isWired)
                    _buildRebootButton(userUid, isOnline),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPinBadge(bool isWired, int? port) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        isWired ? "GPIO PIN: ${port ?? '?'}" : "VIRTUAL OVER LAN",
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: isWired ? const Color(0xFF8E99F3) : Colors.white38,
        ),
      ),
    );
  }

  Widget _buildDirectionBadge(String direction, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        "${direction.toUpperCase()} | ${type.toUpperCase()}",
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white38,
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.25)),
                ),
                Text(
                  val,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRebootButton(String targetUid, bool isOnline) {
    return MouseRegion(
      cursor: isOnline ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: Opacity(
        opacity: isOnline ? 1.0 : 0.4,
        child: GestureDetector(
          onTap: isOnline
              ? () {
                  _showRebootConfirmationDialog(targetUid);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restart_alt_rounded, color: Colors.redAccent, size: 12),
                SizedBox(width: 6),
                Text(
                  "REBOOT HUB",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRebootConfirmationDialog(String targetUid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F111A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
              SizedBox(width: 10),
              Text("Reboot Microcontroller", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text(
            "Are you sure you want to trigger a remote software restart on this microcontroller? This will temporarily interrupt any ongoing sensors sync and relay connections.",
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.12),
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                ),
              ),
              onPressed: () {
                _networkService.rebootUserController(targetUid);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  ScaffoldSnackBar(
                    message: "Soft restart command dispatched to hardware controller.",
                  ),
                );
              },
              child: const Text("CONFIRM REBOOT", style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  // ================= LOGS TAB =================
  Widget _buildLogsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _networkService.listenToGlobalLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E99F3)),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error fetching activity logs: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off_rounded, color: Colors.white24, size: 48),
                const SizedBox(height: 12),
                const Text("No global actions logged yet.", style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildLogItemRow(log),
            );
          },
        );
      },
    );
  }

  Widget _buildLogItemRow(Map<String, dynamic> log) {
    final String message = log["message"] ?? "";
    final String type = log["type"] ?? "general";
    final int timestamp = log["timestamp"] ?? 0;

    final dateStr = timestamp > 0 
        ? DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal().toString().split('.').first.split(' ').last 
        : "--:--:--";

    Color indicatorColor = Colors.grey;
    IconData icon = Icons.circle_outlined;

    switch (type) {
      case "auth":
        indicatorColor = const Color(0xFF8E99F3);
        icon = Icons.key_rounded;
        break;
      case "admin":
        indicatorColor = Colors.amber;
        icon = Icons.admin_panel_settings_rounded;
        break;
      case "device":
        indicatorColor = Colors.cyan;
        icon = Icons.developer_board_rounded;
        break;
      default:
        indicatorColor = Colors.grey;
        icon = Icons.info_outline_rounded;
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      bgOpacity: 0.03,
      borderOpacity: 0.06,
      borderRadius: 10,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Text(
              dateStr,
              style: const TextStyle(
                fontFamily: "monospace",
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white38,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Event Type Icon
          Icon(
            icon,
            color: indicatorColor,
            size: 13,
          ),
          const SizedBox(width: 10),
          // Message Content
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
          // Small log type indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: indicatorColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type.toUpperCase(),
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: indicatorColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScaffoldSnackBar extends SnackBar {
  final String message;

  ScaffoldSnackBar({
    super.key,
    required this.message,
  }) : super(
          backgroundColor: const Color(0xFF0F111A),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: Color(0xFF8E99F3), width: 1),
          ),
          content: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF8E99F3), size: 16),
              SizedBox(width: 10),
              Text(
                message,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        );
}
