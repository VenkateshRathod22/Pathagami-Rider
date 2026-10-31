import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/driver_app_bar.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';
import 'package:bus_driver/driver/presentation/screens/bus_layout/widgets/seat_inspector_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/bus_layout/widgets/sleeper_berth_widget.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/widgets/spot_booking_sheet.dart';
import 'package:bus_driver/driver/core/widgets/crew_drawer.dart';

/// Bus Seat Layout Screen
///
/// Features:
/// - Displays assigned bus's actual 2+1 sleeper layout (Lower & Upper Deck)
/// - Booked, Available, and Unavailable seats styled with distinct colors
/// - Seat numbers, deck selector, and total seat occupancy meter
/// - Safe read-only mode to prevent accidental changes to passenger bookings
/// - Interactive seat inspection sheet for driver verification
class BusSeatLayoutScreen extends StatefulWidget {
  final String? busNumber;
  final String? busType;
  final dynamic tripId;

  const BusSeatLayoutScreen({
    super.key,
    this.busNumber,
    this.busType,
    this.tripId,
  });

  @override
  State<BusSeatLayoutScreen> createState() => _BusSeatLayoutScreenState();
}

class _BusSeatLayoutScreenState extends State<BusSeatLayoutScreen> {
  final DriverRepository _repository = DriverRepository();
  bool _isUpperDeck = false;
  bool _isLoadingVacantSeats = false;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onRepositoryUpdated);
    _loadVacantSeats();
  }

  Future<void> _loadVacantSeats() async {
    if (_repository.vacantSeatsData == null) {
      setState(() => _isLoadingVacantSeats = true);
    }
    final effectiveId = widget.tripId ??
        _repository.selectedTripDetails?.schedule?.id ??
        _repository.activeTrip.id;
    await _repository.fetchVacantSeats(effectiveId);
    if (mounted) {
      setState(() => _isLoadingVacantSeats = false);
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryUpdated);
    super.dispose();
  }

  void _onRepositoryUpdated() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activeTrip = _repository.activeTrip;
    final busNum = widget.busNumber ?? activeTrip.busNumber;
    final busTyp = widget.busType ?? activeTrip.busType;

    final seats = _repository.getSeatsForDeck(isUpperDeck: _isUpperDeck);
    final bookedOnDeck = seats.where((s) => s.isBooked).length;
    final availableOnDeck = seats.length - bookedOnDeck;
    final vacantData = _repository.vacantSeatsData;

    return Scaffold(
      backgroundColor: DriverColors.background,
      drawer: const CrewDrawer(
        currentTabIndex: 3,
        isConductorView: false,
      ),
      appBar: DriverAppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: 'Bus Seat Layout',
        subtitle: '$busNum • $busTyp • Driver: ${_repository.driverName} • Conductor: ${_repository.conductorName}',
        actions: [
          IconButton(
            icon: _isLoadingVacantSeats
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _isLoadingVacantSeats ? null : _loadVacantSeats,
            tooltip: 'Refresh Vacant Seats',
          ),
        ],
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
      body: RefreshIndicator(
        onRefresh: _loadVacantSeats,
        color: DriverColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top Green Banner (Departure Time, Estimated Arrival, Passenger Load)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFA7F3D0), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            activeTrip.departureTime,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
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
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFA7F3D0), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              activeTrip.arrivalTime,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
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
                              'PASSENGER LOAD',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFA7F3D0), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${_repository.bookedSeats} / ${_repository.totalSeats} Seats',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Live Inventory Banner
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DriverColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DriverColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.airline_seat_recline_extra_rounded, color: DriverColors.success, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${vacantData?.totalVacantSeats ?? availableOnDeck} Vacant Berths',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DriverColors.textPrimary),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: DriverColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'LIVE API',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: DriverColors.success),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vacantData != null
                                ? 'Trip #${vacantData.scheduleId} • Fares: ₹950 – ₹1,000'
                                : 'Tap any berth to inspect live fares & booking info',
                            style: const TextStyle(fontSize: 11.5, color: DriverColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Deck Selector (Lower vs Upper Deck)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DriverColors.border),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDeckTab(
                        label: 'Lower Deck (15 Berths)',
                        isSelected: !_isUpperDeck,
                        onTap: () => setState(() => _isUpperDeck = false),
                      ),
                    ),
                    Expanded(
                      child: _buildDeckTab(
                        label: 'Upper Deck (15 Berths)',
                        isSelected: _isUpperDeck,
                        onTap: () => setState(() => _isUpperDeck = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

            // Color Legend
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DriverColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _LegendItem(color: DriverColors.seatBooked, label: 'Booked / Occupied'),
                  _LegendItem(color: DriverColors.seatAvailable, label: 'Available'),
                  _LegendItem(color: DriverColors.seatUnavailable, label: 'Blocked'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bus Frame Graphic (Cabin Front & Seat Matrix)
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
                  // Front Driver Cockpit Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: DriverColors.primaryDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.airline_seat_recline_extra_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'DRIVER CABIN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.door_front_door_outlined, color: DriverColors.textOnDarkMuted, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Entry Gate',
                              style: TextStyle(
                                fontSize: 11,
                                color: DriverColors.textOnDarkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2+1 Sleeper Grid (Rows 1 to 5)
                  for (int row = 1; row <= 5; row++) ...[
                    _buildSleeperRow(seats, row),
                    if (row < 5) const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: DriverColors.border),
                  const SizedBox(height: 10),

                  // Rear of bus
                  const Center(
                    child: Text(
                      '— BUS REAR / EMERGENCY EXIT —',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: DriverColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Deck Occupancy Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DriverColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isUpperDeck ? 'Upper Deck Occupancy' : 'Lower Deck Occupancy',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$bookedOnDeck Booked • $availableOnDeck Available',
                        style: const TextStyle(
                          fontSize: 12,
                          color: DriverColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tap any seat berth to view passenger booking details.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: DriverColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Tap Seat to Inspect'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDeckTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? DriverColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : DriverColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSleeperRow(List<SeatModel> seats, int row) {
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
        // Left Berth A (Window)
        Expanded(
          flex: 4,
          child: SleeperBerthWidget(
            seat: seatA,
            onTap: () => SeatInspectorSheet.show(context, seatA),
          ),
        ),
        const SizedBox(width: 8),

        // Left Berth B (Aisle)
        Expanded(
          flex: 4,
          child: SleeperBerthWidget(
            seat: seatB,
            onTap: () => SeatInspectorSheet.show(context, seatB),
          ),
        ),

        // Walking Aisle
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

        // Right Berth C (Single Sleeper)
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
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DriverColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
