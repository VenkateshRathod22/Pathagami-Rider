import 'package:flutter/material.dart';
import 'package:bus_driver/conductor/data/repository/conductor_repository.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/status_badge.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/widgets/route_info_card.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/widgets/passenger_details_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/widgets/spot_booking_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/widgets/bus_departed_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/widgets/station_halt_sheet.dart';
import 'package:bus_driver/driver/core/widgets/crew_drawer.dart';

/// SPINGO Conductor Dashboard Screen
///
/// Tailored UI for Bus Conductors:
/// 1. Conductor Cockpit Header: Conductor profile info, assigned bus, date, notifications, and duty switch.
/// 2. Active Crew Pairing Card: Driver & Conductor contact cards.
/// 3. Shift Operations & Seat Inventory (Bookings, Seats, Available Seats, Spot Bookings).
/// 4. Today's Route Overview & Active Trip Status.
/// 5. On-Spot Ticket Generation Button for Conductors.
/// 6. Today's Passenger Manifest & Boarding Checklist.
class ConductorDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final ValueChanged<DriverTrip>? onOpenTripDetails;

  const ConductorDashboardScreen({
    super.key,
    this.onNavigateTab,
    this.onOpenTripDetails,
  });

  @override
  State<ConductorDashboardScreen> createState() => _ConductorDashboardScreenState();
}

class _ConductorDashboardScreenState extends State<ConductorDashboardScreen> {
  final ConductorRepository _conductorRepo = ConductorRepository();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;

  // SPINGO Emerald / Conductor Accent Theme
  static const Color conductorAccent = Color(0xFF059669);
  static const Color conductorLightBg = Color(0xFFECFDF5);

  @override
  void initState() {
    super.initState();
    _conductorRepo.addListener(_onRepositoryUpdated);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _conductorRepo.refreshDashboard(),
      _conductorRepo.fetchTodayTrips(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _conductorRepo.removeListener(_onRepositoryUpdated);
    super.dispose();
  }

  void _onRepositoryUpdated() {
    if (mounted) setState(() {});
  }

  void _toggleDutyStatus(bool value) {
    _conductorRepo.toggleDutyStatus(value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Conductor Shift active: ON DUTY. Ready for passenger boarding!'
              : 'Conductor Shift completed: OFF DUTY.',
        ),
        backgroundColor: value ? conductorAccent : DriverColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openSpotBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const SpotBookingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = _conductorRepo.baseRepo;
    final profile = repo.profile;
    final activeTrip = repo.activeTrip;
    final totalBookings = repo.totalBookings;
    final totalSeats = repo.totalSeats;
    final bookedSeats = repo.bookedSeats;
    final availableSeats = repo.availableSeats;

    final bool isApiActive = repo.dashboardData != null && repo.dashboardData?.activeTrip != null;
    final List<PassengerBooking> displayPassengers;
    if (isApiActive) {
      displayPassengers = activeTrip.passengers.where((p) {
        final isSeed = p.pnr.startsWith('RB202610254');
        return !isSeed;
      }).toList();
    } else {
      displayPassengers = activeTrip.passengers;
    }

    final filteredBookings = displayPassengers.where((p) {
      if (_selectedFilter == 'Boarded') return p.isBoarded;
      if (_selectedFilter == 'Pending') return !p.isBoarded && !p.isCancelled;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.passengerName.toLowerCase().contains(q) ||
            p.phone.toLowerCase().contains(q) ||
            p.seatNumber.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: DriverColors.background,
      drawer: CrewDrawer(
        currentTabIndex: 0,
        onSelectTab: widget.onNavigateTab,
        isConductorView: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _conductorRepo.refreshDashboard();
            if (mounted) setState(() {});
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Cockpit Header App Bar for Conductor
              SliverToBoxAdapter(
                child: _buildCockpitHeader(profile),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (!profile.isOnline) ...[
                      _buildOffDutyWarning(),
                      const SizedBox(height: 14),
                    ],

                    // Quick Action Banner for Conductor (Spot Ticketing)
                    _buildConductorQuickActionBanner(),
                    const SizedBox(height: 16),

                    // Capacity Metrics Summary
                    _buildSummaryCards(
                      totalBookings: totalBookings,
                      totalSeats: totalSeats,
                      bookedSeats: bookedSeats,
                      availableSeats: availableSeats,
                    ),

                    const SizedBox(height: 20),

                    // Route Overview
                    const _SectionHeader(
                      title: "Today's Assigned Route",
                      icon: Icons.alt_route_rounded,
                    ),
                    const SizedBox(height: 10),
                    RouteInfoCard(
                      trip: activeTrip,
                      onViewTripDetails: () {
                        if (widget.onOpenTripDetails != null) {
                          widget.onOpenTripDetails!(activeTrip);
                        } else {
                          widget.onNavigateTab?.call(1);
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    // Conductor Live Dispatch Actions Bar & Stations
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildConductorDispatchPill(
                            label: 'BUS DEPARTED',
                            icon: Icons.directions_bus_rounded,
                            color: const Color(0xFF1D4ED8),
                            onTap: () => BusDepartedSheet.show(context),
                          ),
                          const SizedBox(width: 8),
                          _buildConductorDispatchPill(
                            label: 'STATION HALT',
                            icon: Icons.pause_circle_rounded,
                            color: const Color(0xFF0E7490),
                            onTap: () => StationHaltSheet.show(context),
                          ),
                          const SizedBox(width: 8),
                          _buildConductorDispatchPill(
                            label: '${activeTrip.stops.length} ROUTE STOPS',
                            icon: Icons.alt_route_rounded,
                            color: conductorAccent,
                            onTap: () => StationHaltSheet.show(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Passenger Manifest Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionHeader(
                          title: "Passenger Manifest & Boarding",
                          icon: Icons.assignment_ind_rounded,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: conductorAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${filteredBookings.length} Passengers',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: conductorAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search by passenger name, seat, or phone...',
                        prefixIcon: const Icon(Icons.search_rounded, color: DriverColors.textMuted),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: DriverColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: DriverColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Status filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Pending', 'Boarded'].map((f) {
                          final isSelected = _selectedFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedFilter = f),
                              selectedColor: conductorAccent,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : DriverColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),

              // Passengers Manifest List
              if (filteredBookings.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No passenger bookings found.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = filteredBookings[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: DriverColors.border),
                          ),
                          child: ListTile(
                            onTap: () => PassengerDetailsSheet.show(context, passenger: p),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: p.isBoarded ? conductorLightBg : const Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  p.seatNumber,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: p.isBoarded ? conductorAccent : DriverColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              p.passengerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${p.phone} • ${p.pickupLocation} ➔ ${p.dropLocation}',
                              style: const TextStyle(fontSize: 12, color: DriverColors.textSecondary),
                            ),
                            trailing: StatusBadge(
                              label: p.isBoarded ? 'BOARDED' : 'PENDING',
                              color: p.isBoarded ? conductorAccent : const Color(0xFFD97706),
                              isFilled: true,
                            ),
                          ),
                        );
                      },
                      childCount: filteredBookings.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCockpitHeader(DriverProfile profile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: DriverColors.border, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (ctx) => InkWell(
                  onTap: () => CrewDrawer.open(ctx, currentTabIndex: 0, isConductorView: true, onSelectTab: widget.onNavigateTab),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.menu_rounded, size: 21, color: conductorAccent),
                        SizedBox(width: 6),
                        Icon(Icons.badge_rounded, size: 17, color: conductorAccent),
                        SizedBox(width: 6),
                        Text(
                          'CONDUCTOR PORTAL',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: DriverColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: conductorLightBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: conductorAccent)),
                      SizedBox(width: 5),
                      Text('SYNCING...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: conductorAccent)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: conductorLightBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: conductorAccent),
                      SizedBox(width: 5),
                      Text('LIVE API', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: conductorAccent)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (ctx) => InkWell(
                    onTap: () => CrewDrawer.open(ctx, currentTabIndex: 0, isConductorView: true, onSelectTab: widget.onNavigateTab),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF10B981)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _conductorRepo.conductorName.isNotEmpty ? _conductorRepo.conductorName.substring(0, 1) : 'C',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _conductorRepo.conductorName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bus Conductor • ID: ${_conductorRepo.conductorCrewId}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: conductorAccent),
                                ),
                                Text(
                                  'Bus: ${profile.assignedBusNumber} • ${profile.depotName}',
                                  style: const TextStyle(fontSize: 11.5, color: DriverColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: conductorAccent),
                  SizedBox(width: 6),
                  Text('Today Shift', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  StatusBadge(
                    label: profile.isOnline ? 'ON DUTY' : 'OFF DUTY',
                    color: profile.isOnline ? conductorAccent : DriverColors.error,
                    isFilled: true,
                  ),
                  Switch(
                    value: profile.isOnline,
                    onChanged: _toggleDutyStatus,
                    activeTrackColor: conductorAccent.withValues(alpha: 0.3),
                    activeThumbColor: conductorAccent,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConductorQuickActionBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: conductorLightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: conductorAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'On-Spot Ticket Issue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF065F46)),
                ),
                Text(
                  'Issue instant seats to en-route passengers',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _openSpotBookingSheet,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Book Seat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: conductorAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffDutyWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DriverColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DriverColors.error.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: DriverColors.error, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Conductor shift is OFF DUTY. Toggle switch to go online.',
              style: TextStyle(fontSize: 12, color: DriverColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required int totalBookings,
    required int totalSeats,
    required int bookedSeats,
    required int availableSeats,
  }) {
    return Row(
      children: [
        Expanded(
          child: _ConductorMetricCard(
            title: 'Active Bookings',
            value: '$totalBookings',
            subtitle: 'Manifest List',
            color: conductorAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ConductorMetricCard(
            title: 'Booked Seats',
            value: '$bookedSeats',
            subtitle: 'Occupied',
            color: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ConductorMetricCard(
            title: 'Available',
            value: '$availableSeats',
            subtitle: 'Open Seats',
            color: const Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _buildConductorDispatchPill({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF059669)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DriverColors.textPrimary),
        ),
      ],
    );
  }
}

class _ConductorMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _ConductorMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: DriverColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: DriverColors.textMuted)),
        ],
      ),
    );
  }
}
