import 'package:flutter/material.dart';
import 'package:bus_driver/api/api.dart';
import 'package:bus_driver/auth/presentation/screen/logout_screen.dart';
import 'package:bus_driver/conductor/presentation/screens/main_nav/conductor_main_navigation_screen.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';
import 'package:bus_driver/driver/presentation/screens/main_nav/driver_main_navigation_screen.dart';

/// Professional Navigation Drawer / Sidebar for Tripride Bus Crew (Driver & Conductor)
///
/// Features:
/// - App Branding: Tripride logo and subtitle
/// - Authenticated Crew Member Identity (Avatar, Name, ID, Role Badge, Depot, Duty Status)
/// - Role-Based Dashboard Navigation (Driver Dashboard vs Conductor Dashboard with authorization guard)
/// - Core Operational Links (My Trips, Passengers Manifest, My Bus Layout, Crew Profile)
/// - Session Logout with confirmation
class CrewDrawer extends StatelessWidget {
  final int currentTabIndex;
  final ValueChanged<int>? onSelectTab;
  final bool isConductorView;

  const CrewDrawer({
    super.key,
    required this.currentTabIndex,
    this.onSelectTab,
    this.isConductorView = false,
  });

  /// Open the Crew Sidebar from any context or page safely.
  /// First attempts to open the nearest Scaffold drawer; if none exists or hasDrawer is false,
  /// displays the CrewDrawer in a modern modal sheet so sidebar data is always accessible.
  static void open(
    BuildContext context, {
    int currentTabIndex = 0,
    bool isConductorView = false,
    ValueChanged<int>? onSelectTab,
  }) {
    try {
      final scaffold = Scaffold.maybeOf(context);
      if (scaffold != null && scaffold.hasDrawer) {
        scaffold.openDrawer();
        return;
      }
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.94,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: CrewDrawer(
            currentTabIndex: currentTabIndex,
            isConductorView: isConductorView,
            onSelectTab: onSelectTab,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = DriverRepository();
    final profile = repo.profile;
    final crew = repo.crewProfile?.crewDetails;
    final displayName = repo.crewProfile?.name ?? profile.name;
    final displayId = crew?.crewId ?? profile.id;
    final roleLabel = crew?.roleLabel ?? (repo.isConductor ? 'Bus Conductor' : 'Bus Driver');
    final isOnline = profile.isOnline;
    final busNumber = profile.assignedBusNumber;
    final depot = profile.depotName;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Drawer Header with Tripride Branding & Crew Member Identity
            Container(
              padding: const EdgeInsets.fromLTRB(18, 48, 18, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Brand Bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Color(0xFF67E8F9),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tripride',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'CREW OPERATIONS PORTAL',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Crew Member Card
                  Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isConductorView
                                  ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)])
                                  : DriverColors.blueAccentGradient,
                              border: Border.all(color: Colors.white24, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'C',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: isOnline ? DriverColors.success : DriverColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$roleLabel • ID: $displayId',
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Bus: $busNumber • $depot',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Duty Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF064E3B).withValues(alpha: 0.6)
                          : const Color(0xFF7F1D1D).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOnline ? const Color(0xFF34D399) : const Color(0xFFF87171),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 7,
                          color: isOnline ? const Color(0xFF34D399) : const Color(0xFFF87171),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'ACTIVE ON DUTY' : 'SHIFT OFFLINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isOnline ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                children: [
                  _buildSectionHeader('DASHBOARDS'),

                  // Driver Dashboard Option
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.drive_eta_rounded,
                    title: 'Driver Dashboard',
                    subtitle: 'Cockpit, Speed & Route Control',
                    isSelected: !isConductorView && currentTabIndex == 0,
                    badgeText: !isConductorView ? 'Active' : 'Tap to Switch',
                    badgeColor: const Color(0xFF1D4ED8),
                    onTap: () => _handleDriverDashboardTap(context, repo),
                  ),

                  // Conductor Dashboard Option
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.badge_rounded,
                    title: 'Conductor Dashboard',
                    subtitle: 'Boarding Desk & Spot Ticketing',
                    isSelected: isConductorView && currentTabIndex == 0,
                    badgeText: isConductorView ? 'Active' : 'Tap to Switch',
                    badgeColor: const Color(0xFF059669),
                    onTap: () => _handleConductorDashboardTap(context, repo),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),

                  _buildSectionHeader('OPERATIONS & ROSTER'),

                  _buildDrawerTile(
                    context: context,
                    icon: Icons.alt_route_rounded,
                    title: 'My Trips',
                    subtitle: "Today's & Upcoming Shifts",
                    isSelected: currentTabIndex == 1,
                    onTap: () => _navigateToTab(context, 1),
                  ),

                  _buildDrawerTile(
                    context: context,
                    icon: Icons.people_alt_rounded,
                    title: 'Passengers',
                    subtitle: 'Passenger Manifest & Check-in',
                    isSelected: currentTabIndex == 2,
                    onTap: () => _navigateToTab(context, 2),
                  ),

                  _buildDrawerTile(
                    context: context,
                    icon: Icons.airline_seat_recline_extra_rounded,
                    title: 'My Bus',
                    subtitle: 'Coach Layout & Berth Inspection',
                    isSelected: currentTabIndex == 3,
                    onTap: () => _navigateToTab(context, 3),
                  ),

                  _buildDrawerTile(
                    context: context,
                    icon: Icons.person_rounded,
                    title: 'Crew Profile',
                    subtitle: 'Credentials, Schedule & Duty Info',
                    isSelected: currentTabIndex == 4,
                    onTap: () => _navigateToTab(context, 4),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),

                  _buildSectionHeader('ACCOUNT'),

                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DriverColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout_rounded, color: DriverColors.error, size: 20),
                    ),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: DriverColors.error,
                      ),
                    ),
                    subtitle: const Text(
                      'Sign out and end current shift',
                      style: TextStyle(fontSize: 11, color: DriverColors.textSecondary),
                    ),
                    onTap: () => _confirmLogout(context, repo),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ],
              ),
            ),

            // Footer info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              alignment: Alignment.center,
              child: const Text(
                'Tripride Crew App • v1.0.0\nSecure Fleet Operations System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  color: DriverColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: DriverColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final activeColor = isConductorView ? const Color(0xFF059669) : DriverColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? activeColor.withValues(alpha: 0.25) : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 19,
              color: isSelected ? Colors.white : DriverColors.textSecondary,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 13.5,
                    color: isSelected ? activeColor : DriverColors.textPrimary,
                  ),
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? activeColor).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: badgeColor ?? activeColor,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? activeColor.withValues(alpha: 0.8) : DriverColors.textSecondary,
            ),
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    Navigator.of(context).pop(); // Close drawer
    if (onSelectTab != null) {
      onSelectTab!(tabIndex);
    }
  }

  void _handleDriverDashboardTap(BuildContext context, DriverRepository repo) async {
    Navigator.of(context).pop(); // Close drawer

    if (!isConductorView) {
      // Already on Driver navigation shell
      onSelectTab?.call(0);
      return;
    }

    repo.setActiveRole('driver');
    await AuthStorage.setRole('driver');

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const DriverMainNavigationScreen(initialIndex: 0),
      ),
      (route) => false,
    );
  }

  void _handleConductorDashboardTap(BuildContext context, DriverRepository repo) async {
    Navigator.of(context).pop(); // Close drawer

    if (isConductorView) {
      // Already on Conductor navigation shell
      onSelectTab?.call(0);
      return;
    }

    repo.setActiveRole('conductor');
    await AuthStorage.setRole('conductor');

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const ConductorMainNavigationScreen(initialIndex: 0),
      ),
      (route) => false,
    );
  }

  void _confirmLogout(BuildContext context, DriverRepository repo) {
    Navigator.of(context).pop(); // Close drawer
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LogoutScreen()),
    );
  }
}
