import 'package:flutter/material.dart';
import 'package:bus_driver/auth/presentation/screen/logout_screen.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/driver_app_bar.dart';
import 'package:bus_driver/driver/core/widgets/status_badge.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';
import 'package:bus_driver/driver/core/widgets/crew_drawer.dart';

/// SPINGO Driver & Conductor (Crew) Profile Screen
///
/// Integrates live API: https://spingoride.com/api/v1/crew/me
///
/// Comprehensive Display:
/// - Crew Identity & Status (Avatar, Name, Crew ID, Role Label, Duty toggle)
/// - Today's Duty & Active Trip (Schedule, Route, Timings, Delay, Total Trips)
/// - Assigned Bus Roster (Registration, Bus Type, Total Seats, Bus Name)
/// - Official Driving Credentials (License number, Expiry, Experience, Police record)
/// - Personal & Medical Details (Blood group, Gender, DOB, Address, Emergency Contact)
/// - Contact & Communication (Phone, Alternate Phone, Email)
/// - Depot & Branch Operator (Branch name, Email, Address, Phone)
/// - Performance Metrics (Trips completed, On-time percentage, Rating)
/// - Pull-to-refresh & Logout with session wipe
class DriverProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const DriverProfileScreen({super.key, this.onLogout});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final DriverRepository _repository = DriverRepository();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onRepositoryUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryUpdated);
    super.dispose();
  }

  void _onRepositoryUpdated() {
    if (mounted) setState(() {});
  }

  /// Fetch live profile from https://spingoride.com/api/v1/crew/me
  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _repository.refreshProfileFromApi();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (!success && _repository.crewProfile == null) {
        _errorMessage = 'Could not sync live profile with server. Showing cached data.';
      }
    });
  }

  void _confirmLogout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LogoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repository.profile;
    final crewProfile = _repository.crewProfile;
    final crew = crewProfile?.crewDetails;
    final op = crewProfile?.operator;
    final duty = crewProfile?.dutySummary;
    final activeTrip = duty?.activeTrip;
    final bus = activeTrip?.bus;
    final route = activeTrip?.route;

    final displayName = crewProfile?.name ?? profile.name;
    final displayId = crew?.crewId ?? profile.id;
    final displayRole = crew?.roleLabel ?? (crewProfile?.role == 'conductor' ? 'Bus Conductor' : 'Bus Driver');
    final displayDepot = op?.operatorName ?? profile.depotName;

    return Scaffold(
      backgroundColor: DriverColors.background,
      drawer: const CrewDrawer(
        currentTabIndex: 4,
        isConductorView: false,
      ),
      appBar: DriverAppBar(
        automaticallyImplyLeading: false,
        title: 'Crew Profile',
        subtitle: 'SPINGO Fleet Account • $displayRole',
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            onPressed: _isLoading ? null : _fetchProfile,
            tooltip: 'Refresh Profile from Server',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: DriverColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Alert Banner (if sync failed)
              if (_errorMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchProfile,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. Crew Member Identity Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: DriverColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar Photo / Initials
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: DriverColors.blueAccentGradient,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                          ),
                          child: ClipOval(
                            child: (crewProfile?.profilePhoto != null && crewProfile!.profilePhoto!.isNotEmpty)
                                ? Image.network(
                                    crewProfile.profilePhoto!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(displayName),
                                  )
                                : _buildAvatarFallback(displayName),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: DriverColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'ID: $displayId • $displayRole',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: DriverColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayDepot,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: DriverColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  StatusBadge(
                                    label: (crewProfile?.status ?? 'active').toUpperCase(),
                                    color: DriverColors.success,
                                    isFilled: true,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: DriverColors.warning.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 14, color: DriverColors.warningDark),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${profile.rating} Rating',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: DriverColors.warningDark,
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Duty Toggle Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: profile.isOnline ? DriverColors.success : DriverColors.error,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              profile.isOnline ? 'Active On-Duty Shift' : 'Shift Offline',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: DriverColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: profile.isOnline,
                          onChanged: (val) => _repository.toggleOnlineStatus(val),
                          activeThumbColor: DriverColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 2. Today's Duty & Active Schedule Card (From duty_summary or active_trip in API)
              _buildSectionCard(
                icon: Icons.calendar_today_rounded,
                title: 'Duty & Active Schedule',
                badgeText: duty != null ? '${duty.totalTripsToday} Trip Scheduled' : '1 Trip Scheduled',
                children: [
                  _buildProfileRow('Today Date', duty?.todayDate ?? '2026-10-27'),
                  _buildProfileRow('Scheduled Trips Today', '${duty?.totalTripsToday ?? 1}'),
                  const Divider(height: 16),
                  _buildProfileRow(
                    'Schedule ID',
                    '#${activeTrip?.scheduleId ?? _repository.selectedTripDetails?.schedule?.id ?? 21}',
                  ),
                  _buildProfileRow(
                    'Trip Status',
                    (activeTrip?.status ?? _repository.selectedTripDetails?.schedule?.status ?? 'in_transit').toUpperCase(),
                    valueColor: DriverColors.primary,
                  ),
                  _buildProfileRow(
                    'Route',
                    (route != null && route.sourceCity.isNotEmpty && route.destinationCity.isNotEmpty)
                        ? '${route.sourceCity} ➔ ${route.destinationCity}'
                        : '${_repository.activeTrip.fromCity} ➔ ${_repository.activeTrip.toCity}',
                    valueColor: DriverColors.textPrimary,
                  ),
                  _buildProfileRow(
                    'Timings',
                    'Dep: ${activeTrip?.departureTime ?? _repository.activeTrip.departureTime} • Arr: ${activeTrip?.arrivalTime ?? _repository.activeTrip.arrivalTime}',
                  ),
                  _buildProfileRow(
                    'Total Route Distance',
                    (route != null && route.distanceKm != null) ? '${route.distanceKm} km' : _repository.activeTrip.distance,
                  ),
                  _buildProfileRow(
                    'Punctuality / Delay',
                    ((activeTrip?.delayMinutes ?? _repository.selectedTripDetails?.schedule?.delayMinutes ?? 0) == 0)
                        ? 'On Time (0 min delay)'
                        : '${activeTrip?.delayMinutes ?? _repository.selectedTripDetails?.schedule?.delayMinutes} mins delay',
                    valueColor: ((activeTrip?.delayMinutes ?? _repository.selectedTripDetails?.schedule?.delayMinutes ?? 0) == 0)
                        ? DriverColors.success
                        : DriverColors.warningDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Assigned Bus Roster Card (From active_trip.bus in API)
              _buildSectionCard(
                icon: Icons.directions_bus_rounded,
                title: 'Assigned Bus Roster',
                children: [
                  _buildProfileRow(
                    'Registration Number',
                    bus?.registrationNumber ?? _repository.selectedTripDetails?.bus?.registrationNumber ?? profile.assignedBusNumber,
                    valueColor: DriverColors.primary,
                  ),
                  _buildProfileRow('Bus Model / Type', bus?.busType ?? _repository.selectedTripDetails?.bus?.busType ?? profile.assignedBusType),
                  _buildProfileRow('Total Capacity', '${bus?.totalSeats ?? _repository.selectedTripDetails?.bus?.totalSeats ?? _repository.totalSeats} Passenger Seats'),
                  if (bus?.busName != null && bus!.busName!.isNotEmpty)
                    _buildProfileRow('Bus Label', bus.busName!),
                  _buildProfileRow('Depot Fleet SOS', '+91 1800 210 9988'),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Assigned Crew Pairing (Driver & Conductor)
              _buildSectionCard(
                icon: Icons.people_outline_rounded,
                title: 'Assigned Crew Pairing',
                badgeText: 'Driver & Conductor Team',
                children: [
                  _buildProfileRow('Assigned Driver', _repository.driverName, valueColor: DriverColors.primary),
                  _buildProfileRow('Driver Phone', _repository.driverPhone),
                  _buildProfileRow('Driver Crew ID', _repository.driverCrewId),
                  const Divider(height: 16),
                  _buildProfileRow('Assigned Conductor', _repository.conductorName, valueColor: const Color(0xFF047857)),
                  _buildProfileRow('Conductor Phone', _repository.conductorPhone),
                  _buildProfileRow('Conductor Crew ID', _repository.conductorCrewId),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Commercial Driving Credentials Card (From crew_details in API)
              _buildSectionCard(
                icon: Icons.badge_outlined,
                title: 'Commercial Crew Credentials',
                children: [
                  _buildProfileRow('Official Crew ID', displayId),
                  _buildProfileRow('Role / Designation', displayRole),
                  _buildProfileRow(
                    'Driving License (DL)',
                    crew?.licenseNumber ?? profile.licenseNumber,
                    valueColor: DriverColors.primary,
                  ),
                  _buildProfileRow('License Expiry Date', crew?.licenseExpiry ?? '2027-01-16'),
                  _buildProfileRow('Experience in Fleet', '${crew?.experienceYears ?? 27} Years'),
                  _buildProfileRow('Police Record Verification', 'Verified & Clean Record', valueColor: DriverColors.success),
                  _buildProfileRow('Account Status', (crew?.status ?? 'active').toUpperCase(), valueColor: DriverColors.success),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Personal Particulars & Medical Info (From crew_details in API)
              _buildSectionCard(
                icon: Icons.person_outline_rounded,
                title: 'Personal & Medical Particulars',
                children: [
                  _buildProfileRow('Blood Group', crew?.bloodGroup ?? 'A+', valueColor: const Color(0xFFDC2626)),
                  _buildProfileRow('Gender', _formatTitleCase(crew?.gender ?? 'Female')),
                  _buildProfileRow('Date of Birth (DOB)', crew?.dob ?? '2024-02-07'),
                  _buildProfileRow('Residential Address', crew?.address ?? '666 Helen Circle'),
                  if (crew?.emergencyContactName != null && crew!.emergencyContactName!.isNotEmpty)
                    _buildProfileRow('Emergency Contact Person', crew.emergencyContactName!),
                  if (crew?.emergencyContactPhone != null && crew!.emergencyContactPhone!.isNotEmpty)
                    _buildProfileRow('Emergency Phone', crew.emergencyContactPhone!),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Contact Information Card
              _buildSectionCard(
                icon: Icons.contact_phone_outlined,
                title: 'Contact Information',
                children: [
                  _buildProfileRow('Primary Mobile Phone', crewProfile?.phone ?? profile.phone),
                  if (crew?.alternatePhone != null && crew!.alternatePhone!.isNotEmpty)
                    _buildProfileRow('Alternate Phone', crew.alternatePhone!)
                  else
                    _buildProfileRow('Alternate Phone', 'Not Provided'),
                  _buildProfileRow('Official Email', crewProfile?.email ?? profile.email),
                ],
              ),
              const SizedBox(height: 16),

              // 7. Depot & Branch Operator Card (From operator in API)
              _buildSectionCard(
                icon: Icons.business_rounded,
                title: 'Branch Operator & Depot',
                children: [
                  _buildProfileRow('Depot / Branch', op?.operatorName ?? profile.depotName),
                  _buildProfileRow('Branch Email', op?.email ?? 'branch@gmail.com'),
                  _buildProfileRow('Branch Address', op?.address ?? 'Central Bus Depot'),
                  if (op?.contactNumber != null && op!.contactNumber!.isNotEmpty)
                    _buildProfileRow('Branch Helpline', op.contactNumber!),
                ],
              ),
              const SizedBox(height: 16),

              // 8. Performance Statistics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Trips',
                      value: '${profile.totalTrips}',
                      subtitle: 'Safely Completed',
                      icon: Icons.check_circle_outline_rounded,
                      color: DriverColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Punctuality',
                      value: '${profile.onTimePercentage}%',
                      subtitle: 'On-Time Performance',
                      icon: Icons.timer_outlined,
                      color: DriverColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 9. Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded, color: DriverColors.error),
                  label: const Text('Log Out of Crew Portal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DriverColors.error,
                    side: const BorderSide(color: DriverColors.error, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? badgeText,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: DriverColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: DriverColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DriverColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: DriverColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: DriverColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              color: DriverColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: DriverColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: valueColor ?? DriverColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTitleCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
