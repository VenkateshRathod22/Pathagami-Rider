import 'package:flutter/material.dart';
import 'package:bus_driver/api/api.dart';
import 'package:bus_driver/auth/presentation/screen/login_screen.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';

/// SPINGO Crew Logout & Shift Sign-off Screen
///
/// Features:
/// 1. Connects directly to official endpoint: https://spingoride.com/api/v1/crew/logout
/// 2. Summarizes the current crew member shift (Name, Role, Assigned Bus, Route)
/// 3. Safely revokes Bearer token on backend server
/// 4. Wipes local storage via AuthStorage.clearSession()
/// 5. Transitions duty status to Offline
/// 6. Redirects cleanly to LoginScreen with confirmation feedback
class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  final DriverRepository _repository = DriverRepository();
  bool _isLoggingOut = false;
  String? _errorMessage;

  // SPINGO Palette
  static const Color brandDark = Color(0xFF0F172A);
  static const Color brandMuted = Color(0xFF64748B);
  static const Color brandRed = Color(0xFFDC2626);
  static const Color brandRedLight = Color(0xFFFEF2F2);
  static const Color brandRedBorder = Color(0xFFFCA5A5);
  static const Color brandGreen = Color(0xFF16A34A);

  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
      _errorMessage = null;
    });

    try {
      // 1. Call official SPINGO server logout endpoint (/crew/logout)
      final response = await _repository.logout();

      if (!mounted) return;

      // 2. Display success feedback message from server
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  response.message.isNotEmpty
                      ? response.message
                      : 'Successfully logged out. Access token has been revoked.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: brandGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // 3. Clear navigation stack and return to Login Screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoggingOut = false;
        _errorMessage = 'Logout encountered an issue: ${e.toString()}';
      });
    }
  }

  Future<void> _handleForceLogout() async {
    // Clear storage locally and redirect
    _repository.toggleOnlineStatus(false);
    await AuthStorage.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repository.profile;
    final crew = _repository.crewProfile?.crewDetails;
    final activeTrip = _repository.activeTrip;
    final isConductor = _repository.isConductor;

    final displayName = _repository.crewProfile?.name ?? profile.name;
    final displayId = crew?.crewId ?? (isConductor ? 'CND00001' : 'DRV00001');
    final roleLabel = crew?.roleLabel ?? (isConductor ? 'Bus Conductor' : 'Bus Driver');
    final busNumber = profile.assignedBusNumber.isNotEmpty
        ? profile.assignedBusNumber
        : (activeTrip.busNumber.isNotEmpty ? activeTrip.busNumber : 'UP-32-BT-9999');
    final routeText = '${activeTrip.fromCity} ➔ ${activeTrip.toCity}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: brandDark, size: 20),
          onPressed: _isLoggingOut ? null : () => Navigator.of(context).pop(),
          tooltip: 'Back to Dashboard',
        ),
        title: const Text(
          'End Shift & Log Out',
          style: TextStyle(
            color: brandDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Hero Logout Visual Badge
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: brandRedLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: brandRedBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: brandRed.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    size: 44,
                    color: brandRed,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'Sign Out of Crew Shift?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: brandDark,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Your current session and access token will be revoked on the SPINGO fleet server.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: brandMuted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Error Alert (if any)
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: brandRedLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: brandRedBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: brandRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: brandRed,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _handleForceLogout,
                        child: const Text(
                          'Force Offline Sign-out',
                          style: TextStyle(color: brandRed, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Crew Member Shift Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isConductor
                              ? const Color(0xFF059669)
                              : const Color(0xFF1D4ED8),
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
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
                                  color: brandDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isConductor
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      roleLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isConductor
                                            ? const Color(0xFF047857)
                                            : const Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ID: $displayId',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: brandMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ),

                    // Bus & Route Info
                    _buildSummaryRow(
                      icon: Icons.directions_bus_rounded,
                      title: 'Assigned Vehicle',
                      value: busNumber,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      icon: Icons.alt_route_rounded,
                      title: 'Today Route',
                      value: routeText,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      icon: Icons.circle,
                      title: 'Current Status',
                      value: 'Active On Duty',
                      valueColor: brandGreen,
                      iconColor: brandGreen,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Operational Warning Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Confirming will end your shift and set your vehicle availability to offline. You will need your credentials to log in again.',
                        style: TextStyle(
                          color: const Color(0xFF92400E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Confirm Logout Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoggingOut ? null : _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: brandRed.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoggingOut
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'End Shift & Log Out',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel / Stay On Duty Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isLoggingOut ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandDark,
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancel & Stay On Duty',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: brandDark,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? brandMuted),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            color: brandMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor ?? brandDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
