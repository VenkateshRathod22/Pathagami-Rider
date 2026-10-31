import 'package:flutter/material.dart';
import 'package:bus_driver/api/api.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/status_badge.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/widgets/route_info_card.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/widgets/bus_departed_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/widgets/station_halt_sheet.dart';
import 'package:bus_driver/driver/core/widgets/crew_drawer.dart';

/// Bus Driver Home Dashboard Screen
///
/// Features:
/// 1. Cockpit Header: Driver profile, assigned bus number & registration, today's date,
///    notifications icon, and duty switch.
/// 2. Four Summary Cards:
///    - Total Bookings
///    - Total Bus Seats
///    - Booked Seats
///    - Available Seats (Total - Booked, excluding cancelled)
/// 3. Assigned Ride / Route Overview (Where bus has to go: From -> To, times, next stop)
/// 4. Fleet Buses Active at Current Terminal / Route (Live location bus count)
/// 5. Bus Seat Occupancy & Layout Inspection ("bus ka seat dekhna")
/// 6. Today's Bookings Manifest:
///    - Filter Tabs: All, Upcoming, In Progress, Completed, Cancelled
///    - Booking Cards with ID, Name, Phone, From/To, Journey Date/Time, Seats, Status, Payment, View Details
/// 7. Interactive Booking Details Modal Sheet with validated lifecycle transitions:
///    Requested → Accepted → Confirmed → Driver Arriving → Driver Arrived → Ride Started → Ride Completed
class DriverDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final ValueChanged<DriverTrip>? onOpenTripDetails;

  const DriverDashboardScreen({
    super.key,
    this.onNavigateTab,
    this.onOpenTripDetails,
  });

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final DriverRepository _repository = DriverRepository();
  String _selectedFilter = 'All'; // 'All', 'Upcoming', 'In Progress', 'Completed', 'Cancelled'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onRepositoryUpdated);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _repository.refreshDashboardFromApi(),
      _repository.fetchAssignedTrips(filter: 'today'),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _repository.removeListener(_onRepositoryUpdated);
    super.dispose();
  }

  void _onRepositoryUpdated() {
    if (mounted) setState(() {});
  }

  void _toggleDutyStatus(bool value) {
    _repository.toggleOnlineStatus(value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'You are now O'
              'N DUTY. Live dispatch & booking alerts active!'
              : 'You are now OFF DUTY. Have a safe rest!',
        ),
        backgroundColor: value ? DriverColors.success : DriverColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, color: DriverColors.primary, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Dispatch Notifications',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            _buildNotificationItem(
              title: 'Route Clearance Issued',
              body: 'Agra-Lucknow Expressway Toll clearance approved for Bus UP-32-BT-9999.',
              time: '15 mins ago',
              isRead: false,
            ),
            _buildNotificationItem(
              title: 'Passenger Boarding Notice',
              body: 'Passenger Priya Verma arrived at Alambagh ISBT.',
              time: '35 mins ago',
              isRead: false,
            ),
            _buildNotificationItem(
              title: 'Pre-Trip Inspection Required',
              body: 'Complete your driver pre-departure safety checklist before 10:00 PM.',
              time: '1 hr ago',
              isRead: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String body,
    required String time,
    required bool isRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFF8FAFC) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRead ? DriverColors.border : const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRead ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded,
            color: isRead ? DriverColors.textMuted : DriverColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 10.5, color: DriverColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12, color: DriverColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PassengerBooking> _getFilteredBookings(List<PassengerBooking> allBookings) {
    return allBookings.where((booking) {
      // 1. Tab filter
      bool matchesTab = true;
      switch (_selectedFilter) {
        case 'Upcoming':
          matchesTab = booking.rideStatus == RideLifecycleStatus.requested ||
              booking.rideStatus == RideLifecycleStatus.accepted ||
              booking.rideStatus == RideLifecycleStatus.confirmed;
          break;
        case 'In Progress':
          matchesTab = booking.rideStatus == RideLifecycleStatus.driverArriving ||
              booking.rideStatus == RideLifecycleStatus.driverArrived ||
              booking.rideStatus == RideLifecycleStatus.rideStarted;
          break;
        case 'Completed':
          matchesTab = booking.rideStatus == RideLifecycleStatus.rideCompleted;
          break;
        case 'Cancelled':
          matchesTab = booking.rideStatus == RideLifecycleStatus.cancelled;
          break;
        case 'All':
        default:
          matchesTab = true;
      }

      // 2. Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesQuery = booking.passengerName.toLowerCase().contains(q) ||
            booking.phone.toLowerCase().contains(q) ||
            booking.effectiveBookingId.toLowerCase().contains(q) ||
            booking.seatNumber.toLowerCase().contains(q);
        return matchesTab && matchesQuery;
      }

      return matchesTab;
    }).toList();
  }

  void _openBookingDetailsModal(PassengerBooking passenger) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _BookingDetailsSheet(
        passenger: passenger,
        onUpdateStatus: (newStatus) {
          final success = _repository.updateRideLifecycle(passenger.pnr, newStatus);
          if (success) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Booking ${passenger.effectiveBookingId} updated to: ${newStatus.displayName}',
                ),
                backgroundColor: newStatus.color,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onCancelBooking: () {
          final success = _repository.cancelBooking(passenger.pnr);
          if (success) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking cancelled and seat released.'),
                backgroundColor: DriverColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _callPassenger(PassengerBooking passenger) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: DriverColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Call Passenger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Initiate phone call to ${passenger.passengerName}?',
              style: const TextStyle(fontSize: 14, color: DriverColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DriverColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, size: 20, color: DriverColors.primary),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger.passengerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        passenger.phone,
                        style: const TextStyle(color: DriverColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: DriverColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${passenger.passengerName} at ${passenger.phone}...'),
                  backgroundColor: DriverColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Dial Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _callCrewMember({
    required String name,
    required String role,
    required String phone,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: DriverColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('Call $role', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Initiate phone call to $role $name?',
              style: const TextStyle(fontSize: 14, color: DriverColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DriverColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, size: 20, color: DriverColors.primary),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        phone,
                        style: const TextStyle(color: DriverColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: DriverColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling $role $name at $phone...'),
                  backgroundColor: DriverColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Dial Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repository.profile;
    final activeTrip = _repository.activeTrip;
    final totalBookings = _repository.totalBookings;
    final totalSeats = _repository.totalSeats;
    final bookedSeats = _repository.bookedSeats;
    final availableSeats = _repository.availableSeats;
    final dashboardData = _repository.dashboardData;

    final bool isApiActive = dashboardData != null && dashboardData.activeTrip != null;
    final List<PassengerBooking> displayPassengers;
    if (isApiActive) {
      // Show only real API / live spot-booked passengers when live API is loaded
      displayPassengers = activeTrip.passengers.where((p) {
        final isSeed = p.pnr.startsWith('RB202610254');
        return !isSeed;
      }).toList();
    } else {
      displayPassengers = activeTrip.passengers;
    }

    final filteredBookings = _getFilteredBookings(displayPassengers);

    return Scaffold(
      backgroundColor: DriverColors.background,
      drawer: CrewDrawer(
        currentTabIndex: 0,
        onSelectTab: widget.onNavigateTab,
        isConductorView: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _repository.refreshDashboardFromApi();
            if (mounted) setState(() {});
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Cockpit Header App Bar
              SliverToBoxAdapter(
                child: _buildCockpitHeader(profile),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Off-duty notice if driver is offline
                    if (!profile.isOnline) ...[
                      _buildOffDutyWarning(),
                      const SizedBox(height: 14),
                    ],

                    // 1. Shift Operations Metrics from API
                    if (dashboardData?.metrics != null) ...[
                      _buildShiftMetricsSection(dashboardData!.metrics!),
                      const SizedBox(height: 20),
                    ],

                    // 2. Four Key Summary Cards (Capacity & Seating)
                    _buildSummaryCards(
                      totalBookings: totalBookings,
                      totalSeats: totalSeats,
                      bookedSeats: bookedSeats,
                      availableSeats: availableSeats,
                    ),

                    const SizedBox(height: 20),

                    // 3. Live Active Trip from API
                    if (dashboardData?.activeTrip != null) ...[
                      const _SectionHeader(
                        title: "Live Active Trip",
                        icon: Icons.alt_route_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildApiActiveTripCard(dashboardData!.activeTrip!),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Where the bus has to go: Route & Trip info
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
                      const SizedBox(height: 20),
                    ],

                    // 4. Upcoming Scheduled Trips from API
                    if (dashboardData?.upcomingTrips != null &&
                        dashboardData!.upcomingTrips.isNotEmpty) ...[
                      _buildUpcomingTripsSection(dashboardData.upcomingTrips),
                      const SizedBox(height: 20),
                    ],

                    // 5. Bus Seat Occupancy & Layout ("bus ka seat dekhna")
                    _buildSeatLayoutSection(
                      totalSeats: totalSeats,
                      bookedSeats: bookedSeats,
                      availableSeats: availableSeats,
                    ),

                    const SizedBox(height: 24),

                    // 6. Today's Bookings Manifest Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionHeader(
                          title: "Today's Bookings Manifest",
                          icon: Icons.receipt_long_rounded,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: DriverColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${filteredBookings.length} Bookings',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: DriverColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    _buildSearchField(),
                    const SizedBox(height: 12),

                    // Filter Tabs (All, Upcoming, In Progress, Completed, Cancelled)
                    _buildFilterTabs(),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),

              // 7. Today's Booking Cards List
              if (filteredBookings.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No bookings found for "$_selectedFilter"',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
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
                        final booking = filteredBookings[index];
                        return _BookingManifestCard(
                          booking: booking,
                          onViewDetails: () => _openBookingDetailsModal(booking),
                          onCall: () => _callPassenger(booking),
                        );
                      },
                      childCount: filteredBookings.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCockpitHeader(DriverProfile profile) {
    String displayDate = 'Monday, 27 Oct 2026';
    final rawDate = _repository.dashboardData?.metrics?.todayDate ?? _repository.activeTrip.journeyDate;
    if (rawDate.isNotEmpty) {
      try {
        final d = DateTime.parse(rawDate);
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        displayDate = '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
      } catch (_) {
        displayDate = rawDate;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: DriverColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Top Bar with Dashboard label & Live API status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (ctx) => InkWell(
                  onTap: () => CrewDrawer.open(ctx, currentTabIndex: 0, isConductorView: false, onSelectTab: widget.onNavigateTab),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.menu_rounded, size: 21, color: DriverColors.primary),
                        SizedBox(width: 6),
                        Icon(Icons.dashboard_rounded, size: 17, color: DriverColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'DASHBOARD',
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
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2, color: DriverColors.primary),
                      ),
                      SizedBox(width: 5),
                      Text('SYNCING...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DriverColors.primary)),
                    ],
                  ),
                )
              else if (_repository.dashboardData != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                      SizedBox(width: 5),
                      Text('LIVE API', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
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
              // Driver Avatar & Details (Clickable to open Crew Sidebar)
              Expanded(
                child: Builder(
                  builder: (ctx) => InkWell(
                    onTap: () => CrewDrawer.open(ctx, currentTabIndex: 0, isConductorView: false, onSelectTab: widget.onNavigateTab),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          // Driver Avatar with Rating Badge
                          Stack(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  gradient: DriverColors.blueAccentGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    profile.name.isNotEmpty ? profile.name.substring(0, 1) : 'D',
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
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: profile.isOnline ? DriverColors.success : DriverColors.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Driver Name & Assigned Bus Number
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        profile.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: DriverColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${profile.rating}',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD97706),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${profile.badgeType} • ID: ${profile.id}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: DriverColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Bus: ${profile.assignedBusNumber} • ${profile.depotName}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: DriverColors.textSecondary,
                                  ),
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

              // Notification Icon with Badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: DriverColors.textPrimary),
                    onPressed: _showNotificationsSheet,
                    tooltip: 'Notifications',
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Date and Live Duty Switch Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Today's Date with calendar icon
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: DriverColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    displayDate,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              // Duty Switch (On Duty / Off Duty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(
                    label: profile.isOnline ? 'ON DUTY' : 'OFF DUTY',
                    color: profile.isOnline ? DriverColors.success : DriverColors.error,
                    isFilled: true,
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: profile.isOnline,
                    onChanged: _toggleDutyStatus,
                    activeThumbColor: DriverColors.success,
                    activeTrackColor: DriverColors.success.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Assigned Crew Pairing (Driver & Conductor)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DriverColors.border),
            ),
            child: Row(
              children: [
                // Driver Card
                Expanded(
                  child: InkWell(
                    onTap: () => _callCrewMember(
                      name: _repository.driverName,
                      role: 'Driver',
                      phone: _repository.driverPhone,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            gradient: DriverColors.blueAccentGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.drive_eta_rounded, size: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DRIVER',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: DriverColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _repository.driverName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: DriverColors.textPrimary,
                                ),
                              ),
                              Text(
                                '📞 ${_repository.driverPhone}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: DriverColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 38, color: DriverColors.border),
                const SizedBox(width: 8),
                // Conductor Card
                Expanded(
                  child: InkWell(
                    onTap: () => _callCrewMember(
                      name: _repository.conductorName,
                      role: 'Conductor',
                      phone: _repository.conductorPhone,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.badge_rounded, size: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CONDUCTOR',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF047857),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _repository.conductorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: DriverColors.textPrimary,
                                ),
                              ),
                              Text(
                                '📞 ${_repository.conductorPhone}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: DriverColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Route & Intermediate Stations Timeline Ribbon (Displaying All Stop Names)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DriverColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alt_route_rounded, size: 14, color: DriverColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          '${_repository.activeTrip.fromCity} ➔ ${_repository.activeTrip.toCity} • ${_repository.activeTrip.distance} (7.5 hrs)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: DriverColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_repository.activeTrip.stops.length} STATIONS',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: DriverColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _repository.activeTrip.stops.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final stop = entry.value;
                      final isOrigin = idx == 0;
                      final isDest = idx == _repository.activeTrip.stops.length - 1;

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () {
                            if (isOrigin) {
                              BusDepartedSheet.show(context);
                            } else {
                              StationHaltSheet.show(context);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isOrigin
                                  ? const Color(0xFFECFDF5)
                                  : isDest
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isOrigin
                                    ? const Color(0xFFA7F3D0)
                                    : isDest
                                        ? const Color(0xFFBFDBFE)
                                        : DriverColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOrigin
                                      ? Icons.trip_origin_rounded
                                      : isDest
                                          ? Icons.place_rounded
                                          : Icons.radio_button_checked_rounded,
                                  size: 11,
                                  color: isOrigin
                                      ? const Color(0xFF047857)
                                      : isDest
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF0E7490),
                                ),
                                const SizedBox(width: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stop.stopName,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: DriverColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${stop.city} • ${stop.scheduledTime}',
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        color: DriverColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Top Green Banner (Departure Time, Estimated Arrival, Passenger Load)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F059669),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DEPARTURE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA7F3D0),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _repository.activeTrip.departureTime,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EST. ARRIVAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA7F3D0),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _repository.activeTrip.arrivalTime,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LOAD',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA7F3D0),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${_repository.bookedSeats} / ${_repository.totalSeats} Seats',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 4 Live Trip Dispatch Actions Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDispatchActionPill(
                  label: 'BUS DEPARTED',
                  icon: Icons.directions_bus_rounded,
                  color: const Color(0xFF1D4ED8),
                  onTap: () => BusDepartedSheet.show(context),
                ),
                const SizedBox(width: 6),
                _buildDispatchActionPill(
                  label: 'STATION HALT',
                  icon: Icons.pause_circle_rounded,
                  color: const Color(0xFF0E7490),
                  onTap: () => StationHaltSheet.show(context),
                ),
                const SizedBox(width: 6),
                _buildDispatchActionPill(
                  label: 'REPORT DELAY',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFB45309),
                  onTap: _showDashboardDelayDialog,
                ),
                const SizedBox(width: 6),
                _buildDispatchActionPill(
                  label: 'TRIP COMPLETE',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF047857),
                  onTap: _showTripCompleteDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchActionPill({
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
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

  Future<void> _handleDashboardDispatch(String status, String successMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    final effectiveId = _repository.selectedTripDetails?.schedule?.id ?? _repository.activeTrip.id;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Updating dispatch status...'),
        backgroundColor: DriverColors.primary,
        duration: Duration(milliseconds: 600),
      ),
    );

    final res = await _repository.updateTripStatusOnServer(
      tripId: effectiveId,
      status: status,
      operationalNotes: successMessage,
    );

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : successMessage),
          backgroundColor: DriverColors.success,
        ),
      );
    }
  }

  void _showDashboardDelayDialog() {
    int selectedMinutes = 15;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.schedule_rounded, color: Color(0xFFB45309), size: 22),
              SizedBox(width: 8),
              Text('Report Trip Delay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select estimated delay duration for live passenger & depot broadcast:',
                style: TextStyle(fontSize: 13, color: DriverColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [15, 30, 45, 60].map((mins) {
                  final isSelected = selectedMinutes == mins;
                  return ChoiceChip(
                    label: Text('+$mins mins'),
                    selected: isSelected,
                    onSelected: (_) => setDialogState(() => selectedMinutes = mins),
                    selectedColor: const Color(0xFFB45309),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : DriverColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: DriverColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final effectiveId = _repository.selectedTripDetails?.schedule?.id ?? _repository.activeTrip.id;
                await _repository.updateTripStatusOnServer(
                  tripId: effectiveId,
                  status: 'delayed',
                  delayMinutes: selectedMinutes,
                  operationalNotes: 'Traffic congestion delay reported by driver',
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Delay of $selectedMinutes mins broadcasted to dispatch!'),
                      backgroundColor: const Color(0xFFB45309),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Delay'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTripCompleteDialog() {
    final trip = _repository.activeTrip;
    final destStop = trip.stops.isNotEmpty
        ? trip.stops.last.stopName
        : '${trip.toTerminal}, ${trip.toCity}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 22),
            SizedBox(width: 8),
            Text('Complete Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm that the bus has arrived safely at destination terminal:',
              style: TextStyle(fontSize: 13, color: DriverColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_rounded, color: Color(0xFF047857), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destStop,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        Text(
                          'Destination Arrival: ${trip.arrivalTime}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: DriverColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleDashboardDispatch(
                'completed',
                'Arrived at $destStop. Trip marked as COMPLETED!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Completion'),
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
              'You are currently OFF DUTY. Toggle switch in header to go online and receive live passenger bookings.',
              style: TextStyle(
                fontSize: 12,
                color: DriverColors.error,
                fontWeight: FontWeight.w600,
              ),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Bookings',
                value: '$totalBookings',
                subtitle: 'Active Manifest',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF2563EB),
                backgroundColor: const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Total Bus Seats',
                value: '$totalSeats',
                subtitle: 'Capacity (2+1)',
                icon: Icons.airline_seat_recline_extra_rounded,
                color: const Color(0xFF0F172A),
                backgroundColor: const Color(0xFFF1F5F9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Booked Seats',
                value: '$bookedSeats',
                subtitle: 'Reserved Seats',
                icon: Icons.event_seat_rounded,
                color: const Color(0xFFD97706),
                backgroundColor: const Color(0xFFFFFBEB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Available Seats',
                value: '$availableSeats',
                subtitle: 'Total - Booked',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF10B981),
                backgroundColor: const Color(0xFFECFDF5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShiftMetricsSection(DashboardMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: "Today's Operations",
          icon: Icons.analytics_outlined,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Today',
                value: '${metrics.totalToday}',
                subtitle: 'Trips Assigned',
                icon: Icons.alt_route_rounded,
                color: const Color(0xFF2563EB),
                backgroundColor: const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'In Transit',
                value: '${metrics.inTransitToday}',
                subtitle: 'En Route',
                icon: Icons.directions_bus_filled_rounded,
                color: const Color(0xFF059669),
                backgroundColor: const Color(0xFFECFDF5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Scheduled',
                value: '${metrics.scheduledToday}',
                subtitle: 'Upcoming Shifts',
                icon: Icons.schedule_rounded,
                color: const Color(0xFFD97706),
                backgroundColor: const Color(0xFFFFFBEB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Completed',
                value: '${metrics.completedToday}',
                subtitle: 'Finished Shifts',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF6B7280),
                backgroundColor: const Color(0xFFF3F4F6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApiActiveTripCard(DashboardTripItem trip) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Trip ID, Status Badge & Delay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DriverColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TRIP #${trip.id ?? "21"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: DriverColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: trip.delayMinutes == 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trip.delayMinutes == 0 ? 'On Time' : '+${trip.delayMinutes}m delay',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: trip.delayMinutes == 0 ? const Color(0xFF047857) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              StatusBadge(
                label: trip.status.toUpperCase().replaceAll('_', ' '),
                color: trip.status == 'in_transit' ? DriverColors.success : DriverColors.primary,
                isFilled: true,
              ),
            ],
          ),

          // Operational Notes if available
          if (trip.operationalNotes != null && trip.operationalNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_turned_in_rounded, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.operationalNotes!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Route timeline: Origin -> Destination
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DriverColors.border),
            ),
            child: Row(
              children: [
                // Departure
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.departureTime.isNotEmpty ? trip.departureTime : '22:00:00',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip.route?.sourceCity ?? 'Lucknow',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      Text(
                        trip.departureDate,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: DriverColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Connector
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: DriverColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              color: DriverColors.border,
                            ),
                          ),
                          const Icon(Icons.directions_bus_rounded, size: 14, color: DriverColors.primary),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              color: DriverColors.border,
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: DriverColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trip.route?.distanceKm ?? 520} km',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DriverColors.textMuted),
                      ),
                    ],
                  ),
                ),

                // Arrival
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        trip.arrivalTime.isNotEmpty ? trip.arrivalTime : '05:30:00',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip.route?.destinationCity ?? 'Delhi',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      Text(
                        trip.arrivalDate ?? trip.departureDate,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: DriverColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bus Registration & Depot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bus_filled_outlined, size: 16, color: DriverColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${trip.bus?.registrationNumber ?? "UP-32-BT-9999"} • ${trip.bus?.busType ?? "AC Sleeper (2+1)"}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (trip.operator?.operatorName != null)
                Text(
                  trip.operator!.operatorName,
                  style: const TextStyle(fontSize: 11, color: DriverColors.textMuted, fontWeight: FontWeight.w600),
                ),
            ],
          ),

          // Seating availability summary
          if (trip.seating != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${trip.seating!.availableSeats} Seats Available',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                        ),
                        Text(
                          '${trip.seating!.bookedSeats} / ${trip.seating!.totalSeats} Booked',
                          style: const TextStyle(fontSize: 11, color: DriverColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Assigned Crew (Driver & Conductor)
          const Text(
            'Crew On Duty',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: DriverColors.textPrimary),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Driver
              if (trip.driver != null)
                Expanded(
                  child: _buildCrewContactTile(
                    role: 'Driver',
                    person: trip.driver!,
                    icon: Icons.drive_eta_rounded,
                  ),
                ),
              if (trip.driver != null && trip.conductor != null)
                const SizedBox(width: 10),
              // Conductor
              if (trip.conductor != null)
                Expanded(
                  child: _buildCrewContactTile(
                    role: 'Conductor',
                    person: trip.conductor!,
                    icon: Icons.badge_rounded,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrewContactTile({
    required String role,
    required CrewPerson person,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DriverColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: DriverColors.primary),
              const SizedBox(width: 4),
              Text(
                role.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: DriverColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            person.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: DriverColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            person.phone,
            style: const TextStyle(
              fontSize: 11,
              color: DriverColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: OutlinedButton.icon(
              onPressed: person.phone.isNotEmpty
                  ? () => _callCrewMember(name: person.name, role: role, phone: person.phone)
                  : null,
              icon: const Icon(Icons.call_rounded, size: 12),
              label: const Text('Call', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: DriverColors.primary,
                side: const BorderSide(color: DriverColors.primary, width: 1),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTripsSection(List<DashboardTripItem> upcomingTrips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionHeader(
              title: "Upcoming Scheduled Trips",
              icon: Icons.schedule_rounded,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DriverColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${upcomingTrips.length} Upcoming',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: DriverColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...upcomingTrips.map((trip) => _buildUpcomingTripCard(trip)),
      ],
    );
  }

  Widget _buildUpcomingTripCard(DashboardTripItem trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                'TRIP #${trip.id ?? "UP"}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: DriverColors.primary,
                ),
              ),
              StatusBadge(
                label: trip.status.toUpperCase(),
                color: const Color(0xFFD97706),
                isFilled: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.route?.sourceCity ?? "Lucknow"} → ${trip.route?.destinationCity ?? "Delhi"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Departs: ${trip.departureDate} at ${trip.departureTime}',
                      style: const TextStyle(fontSize: 11.5, color: DriverColors.textSecondary),
                    ),
                    Text(
                      'Arrives: ${trip.arrivalDate ?? trip.departureDate} at ${trip.arrivalTime}',
                      style: const TextStyle(fontSize: 11, color: DriverColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${trip.seating?.availableSeats ?? 29} Available',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: DriverColors.success,
                    ),
                  ),
                  Text(
                    '${trip.seating?.bookedSeats ?? 1} Booked',
                    style: const TextStyle(fontSize: 11, color: DriverColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          if (trip.driver != null || trip.conductor != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (trip.driver != null)
                  Text(
                    'Driver: ${trip.driver!.name}',
                    style: const TextStyle(fontSize: 11, color: DriverColors.textMuted),
                  ),
                if (trip.conductor != null)
                  Text(
                    'Conductor: ${trip.conductor!.name}',
                    style: const TextStyle(fontSize: 11, color: DriverColors.textMuted),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeatLayoutSection({
    required int totalSeats,
    required int bookedSeats,
    required int availableSeats,
  }) {
    final double ratio = totalSeats > 0 ? (bookedSeats / totalSeats).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.airline_seat_recline_extra_rounded, color: DriverColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Bus Seat Layout (2+1 Sleeper)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: DriverColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${(ratio * 100).toInt()}% Booked',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: DriverColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Occupancy bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(height: 14),

          // Lower Deck & Upper Deck Quick Details
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DriverColors.border),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Lower Deck',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '15 Berths (L1A-L5C)',
                        style: TextStyle(fontSize: 11, color: DriverColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DriverColors.border),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Upper Deck',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '15 Berths (U1A-U5C)',
                        style: TextStyle(fontSize: 11, color: DriverColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Button to inspect interactive seat layout
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => widget.onNavigateTab?.call(3), // Navigate to My Bus tab
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('Open Interactive Seat Inspection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Search by Passenger Name, Phone, or Seat...',
        hintStyle: const TextStyle(fontSize: 13, color: DriverColors.textMuted),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: DriverColors.primary),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DriverColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DriverColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DriverColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Upcoming', 'In Progress', 'Completed', 'Cancelled'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedFilter = filter);
              },
              selectedColor: DriverColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : DriverColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12.5,
              ),
              side: BorderSide(
                color: isSelected ? DriverColors.primary : DriverColors.border,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 4 Summary Metric Card Component
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: DriverColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: DriverColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual Card for each booking in Today's Manifest
class _BookingManifestCard extends StatelessWidget {
  final PassengerBooking booking;
  final VoidCallback onViewDetails;
  final VoidCallback onCall;

  const _BookingManifestCard({
    required this.booking,
    required this.onViewDetails,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = booking.isCancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled ? DriverColors.error.withValues(alpha: 0.3) : DriverColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Booking ID, Seat Badge, and Status
            Row(
              children: [
                // Seat Number Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: DriverColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DriverColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        booking.seatNumber,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: DriverColors.primary,
                        ),
                      ),
                      Text(
                        booking.isUpperDeck ? 'UPPER' : 'LOWER',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: DriverColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Booking ID and Passenger Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            booking.effectiveBookingId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: DriverColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${booking.passengerCount} Seat',
                            style: const TextStyle(fontSize: 11, color: DriverColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.passengerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Phone: ${booking.phone}',
                        style: const TextStyle(fontSize: 11.5, color: DriverColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                StatusBadge(
                  label: booking.rideStatus.displayName.toUpperCase(),
                  color: booking.rideStatus.color,
                  isFilled: true,
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Route Points: Pickup & Drop
            Row(
              children: [
                const Icon(Icons.trip_origin_rounded, size: 14, color: Color(0xFF0284C7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pickup (${booking.pickupTime}): ${booking.pickupLocation}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Drop (${booking.dropTime}): ${booking.dropLocation}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Actions & Payment Status
            Row(
              children: [
                // Payment Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        booking.paymentStatus,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Call Button
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: DriverColors.primary, size: 20),
                  onPressed: onCall,
                  tooltip: 'Call Passenger',
                ),

                // "View Details" Primary Action
                ElevatedButton(
                  onPressed: onViewDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Comprehensive Booking Details Bottom Sheet with Validated Lifecycle Stepper
class _BookingDetailsSheet extends StatelessWidget {
  final PassengerBooking passenger;
  final ValueChanged<RideLifecycleStatus> onUpdateStatus;
  final VoidCallback onCancelBooking;

  const _BookingDetailsSheet({
    required this.passenger,
    required this.onUpdateStatus,
    required this.onCancelBooking,
  });

  @override
  Widget build(BuildContext context) {
    final rideStatus = passenger.rideStatus;
    final nextStatus = rideStatus.nextStatus;
    final nextActionTitle = rideStatus.nextActionTitle;
    final canCancel = rideStatus != RideLifecycleStatus.rideStarted &&
        rideStatus != RideLifecycleStatus.rideCompleted &&
        rideStatus != RideLifecycleStatus.cancelled;

    // Full business lifecycle sequence
    final lifecycleSteps = [
      RideLifecycleStatus.requested,
      RideLifecycleStatus.accepted,
      RideLifecycleStatus.confirmed,
      RideLifecycleStatus.driverArriving,
      RideLifecycleStatus.driverArrived,
      RideLifecycleStatus.rideStarted,
      RideLifecycleStatus.rideCompleted,
    ];

    final currentStepIndex = lifecycleSteps.indexOf(rideStatus);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking: ${passenger.effectiveBookingId}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'PNR: ${passenger.pnr} • Seat ${passenger.seatNumber}',
                    style: const TextStyle(fontSize: 12, color: DriverColors.textMuted),
                  ),
                ],
              ),
              StatusBadge(
                label: rideStatus.displayName.toUpperCase(),
                color: rideStatus.color,
                isFilled: true,
              ),
            ],
          ),
          const Divider(height: 20),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Passenger details card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DriverColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Passenger Name', passenger.passengerName),
                        _buildDetailRow('Contact Phone', passenger.phone),
                        _buildDetailRow('Gender & Age', '${passenger.gender}, ${passenger.age} yrs'),
                        _buildDetailRow('Booked Berth', '${passenger.seatNumber} (${passenger.isUpperDeck ? "Upper Deck" : "Lower Deck"})'),
                        _buildDetailRow('Fare Amount', '₹${passenger.fare.toStringAsFixed(0)}'),
                        _buildDetailRow('Payment Status', passenger.paymentStatus),
                        _buildDetailRow('Journey Date', passenger.journeyDate),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Route Pickup & Drop
                  const Text('Journey Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DriverColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.trip_origin_rounded, color: Color(0xFF0284C7), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pickup: ${passenger.pickupLocation}\nTime: ${passenger.pickupTime}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Drop: ${passenger.dropLocation}\nTime: ${passenger.dropTime}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Business Ride Lifecycle Stepper
                  const Text(
                    'Ride Lifecycle & Driver Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DriverColors.border),
                    ),
                    child: Column(
                      children: List.generate(lifecycleSteps.length, (index) {
                        final step = lifecycleSteps[index];
                        final bool isCurrent = step == rideStatus;
                        final bool isPassed = currentStepIndex != -1 && index < currentStepIndex;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isPassed
                                    ? Icons.check_circle_rounded
                                    : isCurrent
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                color: isPassed
                                    ? const Color(0xFF10B981)
                                    : isCurrent
                                        ? step.color
                                        : Colors.grey.shade400,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                step.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  color: isCurrent
                                      ? step.color
                                      : isPassed
                                          ? DriverColors.textPrimary
                                          : Colors.grey.shade500,
                                ),
                              ),
                              if (isCurrent) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: step.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: step.color,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons: Only show the next valid transition button!
          if (nextStatus != null && nextActionTitle != null) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => onUpdateStatus(nextStatus),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(nextActionTitle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: nextStatus.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Cancel or Reject Action (only when permitted)
          if (canCancel)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onCancelBooking,
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel / Reject This Booking'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DriverColors.error,
                  side: const BorderSide(color: DriverColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: DriverColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
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
        Icon(icon, size: 18, color: DriverColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: DriverColors.textPrimary,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
