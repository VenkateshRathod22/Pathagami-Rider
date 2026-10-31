import 'package:flutter/material.dart';
import 'package:bus_driver/api/api.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/driver_app_bar.dart';
import 'package:bus_driver/driver/core/widgets/empty_state_widget.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';
import 'package:bus_driver/driver/presentation/screens/bus_layout/widgets/seat_inspector_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/bus_layout/widgets/sleeper_berth_widget.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/widgets/passenger_card.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/widgets/spot_booking_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/widgets/bus_departed_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/widgets/station_halt_sheet.dart';
import 'package:bus_driver/driver/core/widgets/crew_drawer.dart';

/// Passenger List Screen
///
/// Features:
/// - Full passenger manifest with Name, PNR, Booked Seats, Pickup/Drop, and Status
/// - Search by passenger name, phone, or PNR
/// - Filter by Boarding Status (All, Pending, Boarded)
/// - Driver Check-in / Mark Boarded action with instant state update
/// - Quick call prompt
class PassengerListScreen extends StatefulWidget {
  final String? tripId;

  const PassengerListScreen({super.key, this.tripId});

  @override
  State<PassengerListScreen> createState() => _PassengerListScreenState();
}

class _PassengerListScreenState extends State<PassengerListScreen> {
  final DriverRepository _repository = DriverRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Pending', 'Boarded'
  int _masterTabIndex = 0; // 0: Manifest & Boarding, 1: Bus Seating Layout
  bool _isUpperDeck = false;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onRepositoryUpdated);
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

  void _callPassenger(PassengerBooking passenger) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: DriverColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'Call Passenger',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you want to initiate a call to ${passenger.passengerName}?',
              style: const TextStyle(fontSize: 14, color: DriverColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DriverColors.surfaceSecondary,
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
                  content: Text('Dialing ${passenger.passengerName} (${passenger.phone})...'),
                  backgroundColor: DriverColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePassengerBoarding(PassengerBooking passenger, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('Syncing ${passenger.passengerName} as ${status.toUpperCase()}...'),
          ],
        ),
        backgroundColor: DriverColors.primary,
        duration: const Duration(milliseconds: 900),
      ),
    );

    final res = await _repository.confirmPassengerBoardingOnServer(
      passengerId: passenger.effectivePassengerId,
      status: status,
      pnr: passenger.pnr,
    );

    if (mounted) {
      if (res.isSuccess && res.data?.data != null) {
        _showBoardingResultDialog(res.data!.data!, res.data!.message);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty ? res.message : 'Updated status to ${status.toUpperCase()}'),
            backgroundColor: status == 'boarded' ? DriverColors.success : DriverColors.primary,
          ),
        );
      }
    }
  }

  void _showBoardingResultDialog(CrewPassengerBoardingData data, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              data.isBoarded
                  ? Icons.check_circle_rounded
                  : (data.isNoShow ? Icons.cancel_rounded : Icons.pending_rounded),
              color: data.isBoarded
                  ? DriverColors.success
                  : (data.isNoShow ? DriverColors.brandRed : DriverColors.warning),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Boarding Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: DriverColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DriverColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Passenger ID', '#${data.passengerId}'),
                  _buildDetailRow('Passenger Name', data.passengerName),
                  _buildDetailRow('Seat Number', data.seatNumber),
                  _buildDetailRow('Boarding Status', data.boardingStatus.toUpperCase()),
                  if (data.boardedAt != null && data.boardedAt!.isNotEmpty)
                    _buildDetailRow('Boarded At', data.boardedAt!),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
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
          Text(label, style: const TextStyle(fontSize: 12, color: DriverColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: DriverColors.textPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTrip = _repository.activeTrip;
    final passengers = activeTrip.passengers;

    final boardedCount = passengers.where((p) => p.isBoarded).length;
    final noShowCount = passengers.where((p) => p.isNoShow).length;
    final pendingCount = passengers.where((p) => p.isPending).length;
    final totalCount = passengers.length;

    // Filter and search
    final filteredPassengers = passengers.where((p) {
      final matchesSearch = p.passengerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.phone.contains(_searchQuery) ||
          p.pnr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.seatNumber.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedFilter == 'Boarded') return p.isBoarded;
      if (_selectedFilter == 'Pending') return p.isPending;
      if (_selectedFilter == 'No-Show') return p.isNoShow;
      return true;
    }).toList();

    final driverName = _repository.driverName;
    final conductorName = _repository.conductorName;
    final vacantSeatsCount = _repository.vacantSeatsData?.totalVacantSeats ??
        (_repository.totalSeats - activeTrip.activeBookedSeatsCount);

    return Scaffold(
      backgroundColor: DriverColors.background,
      drawer: const CrewDrawer(
        currentTabIndex: 2,
        isConductorView: false,
      ),
      appBar: DriverAppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: 'Passenger Manifest',
        subtitle: 'Driver: $driverName • Conductor: $conductorName',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SpotBookingSheet.show(context),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.bolt_rounded, size: 20),
        label: const Text(
          'Book Berth',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
      body: Column(
        children: [
          // Top Green Banner (Departure Time, Estimated Arrival, Passenger Load)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F059669),
                  blurRadius: 8,
                  offset: Offset(0, 3),
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
                        'DEPARTURE TIME',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA7F3D0),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeTrip.departureTime,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.white24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESTIMATED ARRIVAL',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA7F3D0),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeTrip.arrivalTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.white24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PASSENGER LOAD',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA7F3D0),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$boardedCount / ${activeTrip.totalSeats} Seats',
                          style: const TextStyle(
                            fontSize: 14,
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

          // Live Trip Dispatch Actions Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDispatchButton(
                    label: 'BUS DEPARTED',
                    icon: Icons.directions_bus_rounded,
                    color: const Color(0xFF1D4ED8),
                    onTap: () => BusDepartedSheet.show(context),
                  ),
                  const SizedBox(width: 8),
                  _buildDispatchButton(
                    label: 'STATION HALT',
                    icon: Icons.pause_circle_rounded,
                    color: const Color(0xFF0E7490),
                    onTap: () => StationHaltSheet.show(context),
                  ),
                  const SizedBox(width: 8),
                  _buildDispatchButton(
                    label: 'REPORT DELAY',
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFFB45309),
                    onTap: _showReportDelayDialog,
                  ),
                  const SizedBox(width: 8),
                  _buildDispatchButton(
                    label: 'TRIP COMPLETE',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF047857),
                    onTap: _showTripCompleteDialog,
                  ),
                ],
              ),
            ),
          ),

          // Dual Master Tabs (Matching Web Panel: Tab 1 Manifest, Tab 2 Coach Seating Layout)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            decoration: BoxDecoration(
              color: DriverColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DriverColors.border),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _buildMasterTabItem(
                    index: 0,
                    icon: Icons.people_alt_rounded,
                    title: 'Boarding Manifest',
                    badge: '$boardedCount/$totalCount Boarded',
                    badgeColor: DriverColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMasterTabItem(
                    index: 1,
                    icon: Icons.event_seat_rounded,
                    title: 'Bus Seating Layout',
                    badge: '$vacantSeatsCount Vacant',
                    badgeColor: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),

          // Main Tab Body
          Expanded(
            child: _masterTabIndex == 0
                ? _buildManifestTab(
                    boardedCount: boardedCount,
                    totalCount: totalCount,
                    pendingCount: pendingCount,
                    noShowCount: noShowCount,
                    filteredPassengers: filteredPassengers,
                  )
                : _buildSeatingLayoutTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterTabItem({
    required int index,
    required IconData icon,
    required String title,
    required String badge,
    required Color badgeColor,
  }) {
    final isSelected = _masterTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _masterTabIndex = index),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? DriverColors.primary : DriverColors.textMuted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? DriverColors.textPrimary : DriverColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? badgeColor.withValues(alpha: 0.12) : DriverColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? badgeColor : DriverColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDispatchButton({
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

  Future<void> _handleDispatchAction(String status, String successMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    final effectiveId = widget.tripId ??
        _repository.selectedTripDetails?.schedule?.id ??
        _repository.activeTrip.id;

    messenger.showSnackBar(
      SnackBar(
        content: Text('Updating trip dispatch status...'),
        backgroundColor: DriverColors.primary,
        duration: const Duration(milliseconds: 600),
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

  void _showReportDelayDialog() {
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
                final effectiveId = widget.tripId ??
                    _repository.selectedTripDetails?.schedule?.id ??
                    _repository.activeTrip.id;
                await _repository.updateTripStatusOnServer(
                  tripId: effectiveId,
                  status: 'delayed',
                  delayMinutes: selectedMinutes,
                  operationalNotes: 'Traffic congestion delay reported by crew',
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
              _handleDispatchAction(
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

  Widget _buildManifestTab({
    required int boardedCount,
    required int totalCount,
    required int pendingCount,
    required int noShowCount,
    required List<PassengerBooking> filteredPassengers,
  }) {
    return Column(
      children: [
        // Conductor Check-in Progress Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: DriverColors.border)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_rounded, size: 16, color: DriverColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Conductor Desk • $boardedCount / $totalCount Boarded',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '$pendingCount Pending',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.warningDark,
                        ),
                      ),
                      if (noShowCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$noShowCount No-Show',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: DriverColors.brandRed,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalCount > 0 ? boardedCount / totalCount : 0.0,
                  minHeight: 6,
                  backgroundColor: DriverColors.surfaceSecondary,
                  valueColor: const AlwaysStoppedAnimation<Color>(DriverColors.success),
                ),
              ),
            ],
          ),
        ),

        // Search and Filters
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search by Passenger Name, Seat, or PNR...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: DriverColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  fillColor: DriverColors.surfaceSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'All ($totalCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'Pending ($pendingCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Boarded', 'Boarded ($boardedCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('No-Show', 'No-Show ($noShowCount)'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Passenger Cards List
        Expanded(
          child: filteredPassengers.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.person_search_rounded,
                  title: 'No Passengers Found',
                  message: 'No passengers match the current search or status filter.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPassengers.length,
                  itemBuilder: (context, index) {
                    final passenger = filteredPassengers[index];
                    return PassengerCard(
                      passenger: passenger,
                      onToggleBoarding: () {
                        _updatePassengerBoarding(
                          passenger,
                          passenger.isBoarded ? 'pending' : 'boarded',
                        );
                      },
                      onUpdateStatus: (status) {
                        _updatePassengerBoarding(passenger, status);
                      },
                      onCallPassenger: () => _callPassenger(passenger),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSeatingLayoutTab() {
    final seats = _repository.getSeatsForDeck(isUpperDeck: _isUpperDeck);
    final totalSeats = _repository.totalSeats;
    final bookedSeats = _repository.bookedSeats;
    final vacantSeats = _repository.vacantSeatsData?.totalVacantSeats ??
        (totalSeats - bookedSeats);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Matching Web Panel Screenshot 2)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DriverColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Bus Seating Layout (Coach Map)',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total Capacity: $totalSeats Seats • Booked: $bookedSeats • Vacant: $vacantSeats',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: DriverColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => SpotBookingSheet.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF047857)),
                          SizedBox(width: 4),
                          Text(
                            'Spot Booking',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Legend Bar (Available, Booked Pending, Booked Boarded, Booked No-Show)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DriverColors.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLegendPill(color: const Color(0xFF10B981), label: 'Available (₹ Live Fare)', isOutline: true),
                  const SizedBox(width: 10),
                  _buildLegendPill(color: const Color(0xFFF59E0B), label: 'Booked Pending', isOutline: false),
                  const SizedBox(width: 10),
                  _buildLegendPill(color: const Color(0xFF10B981), label: 'Booked Boarded', isOutline: false),
                  const SizedBox(width: 10),
                  _buildLegendPill(color: const Color(0xFFEF4444), label: 'Booked No-Show', isOutline: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Deck Toggle Buttons (Lower Deck Coach 15 Seats / Upper Deck Coach 15 Berths)
          Container(
            decoration: BoxDecoration(
              color: DriverColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DriverColors.border),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _buildDeckToggleButton(
                    label: 'Lower Deck Coach (15 Seats)',
                    isSelected: !_isUpperDeck,
                    onTap: () => setState(() => _isUpperDeck = false),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildDeckToggleButton(
                    label: 'Upper Deck Coach (15 Berths)',
                    isSelected: _isUpperDeck,
                    onTap: () => setState(() => _isUpperDeck = true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Coach Body Graphic
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DriverColors.border, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Front Cockpit & Entry
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: DriverColors.primaryDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.door_front_door_outlined, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            '-> ENTRY / DOOR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.airline_seat_recline_extra_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Front / Driver Cabin',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2+1 Sleeper Grid (Rows 1 to 5)
                for (int row = 1; row <= 5; row++) ...[
                  _buildCoachSleeperRow(seats, row),
                  if (row < 5) const SizedBox(height: 12),
                ],

                const SizedBox(height: 16),
                const Divider(color: DriverColors.border),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    '— BUS REAR / EMERGENCY EXIT —',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: DriverColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCoachSleeperRow(List<SeatModel> seats, int row) {
    final seatA = seats.firstWhere(
      (s) => s.row == row && s.column == 0,
      orElse: () => SeatModel(seatNumber: 'A', row: row, column: 0, isUpperDeck: _isUpperDeck, isSleeper: true, isBooked: false),
    );
    final seatB = seats.firstWhere(
      (s) => s.row == row && s.column == 1,
      orElse: () => SeatModel(seatNumber: 'B', row: row, column: 1, isUpperDeck: _isUpperDeck, isSleeper: true, isBooked: false),
    );
    final seatC = seats.firstWhere(
      (s) => s.row == row && s.column == 3,
      orElse: () => SeatModel(seatNumber: 'C', row: row, column: 3, isUpperDeck: _isUpperDeck, isSleeper: true, isBooked: false),
    );

    return Row(
      children: [
        // Left Berth A
        Expanded(
          flex: 4,
          child: SleeperBerthWidget(
            seat: seatA,
            onTap: () => SeatInspectorSheet.show(context, seatA),
          ),
        ),
        const SizedBox(width: 8),

        // Left Berth B
        Expanded(
          flex: 4,
          child: SleeperBerthWidget(
            seat: seatB,
            onTap: () => SeatInspectorSheet.show(context, seatB),
          ),
        ),

        // Aisle
        Expanded(
          flex: 3,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text(
                'AISLE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: DriverColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),

        // Right Berth C (Single Berth)
        Expanded(
          flex: 4,
          child: SleeperBerthWidget(
            seat: seatC,
            onTap: () => SeatInspectorSheet.show(context, seatC),
          ),
        ),
      ],
    );
  }

  Widget _buildDeckToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? DriverColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : DriverColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendPill({
    required Color color,
    required String label,
    required bool isOutline,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOutline ? Colors.white : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isOutline ? DriverColors.textPrimary : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filterKey),
      selectedColor: DriverColors.primary,
      backgroundColor: DriverColors.surfaceSecondary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : DriverColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? DriverColors.primary : DriverColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}
