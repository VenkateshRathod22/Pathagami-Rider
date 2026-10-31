import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';

/// Modal bottom sheet for logging a Station Halt at an intermediate route stop
/// Displays full station/stop names, scheduled timings, boarding/dropping counts,
/// halt reasons, duration, and operational notes for the crew.
class StationHaltSheet extends StatefulWidget {
  final VoidCallback? onHaltLogged;

  const StationHaltSheet({super.key, this.onHaltLogged});

  static Future<void> show(BuildContext context, {VoidCallback? onHaltLogged}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StationHaltSheet(onHaltLogged: onHaltLogged),
    );
  }

  @override
  State<StationHaltSheet> createState() => _StationHaltSheetState();
}

class _StationHaltSheetState extends State<StationHaltSheet> {
  final DriverRepository _repository = DriverRepository();
  late TextEditingController _notesController;

  late List<RouteStop> _stops;
  late RouteStop _selectedStop;
  String _selectedReason = 'Passenger Boarding';
  int _selectedMinutes = 15;
  bool _isSubmitting = false;

  final List<String> _haltReasons = [
    'Passenger Boarding',
    'Refreshment / Break',
    'Toll Plaza Halt',
    'Fuel Refill',
    'Traffic / Inspection',
  ];

  final List<int> _durationOptions = [5, 10, 15, 20, 30, 45];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _initStopsFromApi();

    // Fetch live trip details from API if not yet cached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final effectiveId =
          _repository.selectedTripDetails?.schedule?.id ??
          _repository.dashboardData?.activeTrip?.id ??
          (int.tryParse(_repository.activeTrip.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 19);
      _fetchLiveTripDetails(effectiveId);
    });
  }

  void _initStopsFromApi() {
    final activeApi = _repository.dashboardData?.activeTrip;
    final tripDetails = _repository.selectedTripDetails;
    final trip = _repository.activeTrip;

    final fromCity = tripDetails?.route?.sourceCity ??
        activeApi?.route?.sourceCity ??
        trip.fromCity;
    final toCity = tripDetails?.route?.destinationCity ??
        activeApi?.route?.destinationCity ??
        trip.toCity;
    final depTime = tripDetails?.schedule?.departureTime ??
        activeApi?.departureTime ??
        trip.departureTime;
    final arrTime = tripDetails?.schedule?.arrivalTime ??
        activeApi?.arrivalTime ??
        trip.arrivalTime;
    final totalSeats = tripDetails?.seatingSummary?.totalSeats ??
        activeApi?.seating?.totalSeats ??
        _repository.totalSeats;
    final bookedSeats = tripDetails?.seatingSummary?.bookedSeatsCount ??
        activeApi?.seating?.bookedSeats ??
        _repository.bookedSeats;

    _stops = _buildDynamicStops(
      fromCity: fromCity,
      toCity: toCity,
      departureTime: depTime,
      arrivalTime: arrTime,
      bookedSeats: bookedSeats,
      totalSeats: totalSeats,
    );

    _selectedStop = _stops.firstWhere(
      (s) => s.isNext || !s.isPassed,
      orElse: () => _stops.length > 1 ? _stops[1] : _stops.first,
    );

    _updateOperationalNotes();
  }

  Future<void> _fetchLiveTripDetails(dynamic tripId) async {
    try {
      final details = await _repository.fetchTripDetails(tripId);
      if (details != null && mounted) {
        setState(() {
          _initStopsFromApi();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateOperationalNotes() {
    _notesController.text =
        'Station Halt at ${_selectedStop.stopName} (${_selectedStop.city}) - $_selectedReason ($_selectedMinutes mins)';
  }

  List<RouteStop> _buildDynamicStops({
    required String fromCity,
    required String toCity,
    required String departureTime,
    required String arrivalTime,
    required int bookedSeats,
    required int totalSeats,
  }) {
    // If the route is Lucknow -> Delhi (or standard route)
    if (fromCity.toLowerCase().contains('lucknow') &&
        toCity.toLowerCase().contains('delhi')) {
      final b1 = (bookedSeats * 0.65).round();
      final b2 = (bookedSeats - b1).clamp(0, bookedSeats);
      final d1 = (bookedSeats * 0.1).round();
      final d2 = (bookedSeats * 0.35).round();
      final d3 = (bookedSeats - d1 - d2).clamp(0, bookedSeats);

      return [
        RouteStop(
          id: 'stop-1',
          stopName: 'Alambagh Bus Terminal',
          city: fromCity,
          scheduledTime: departureTime.isNotEmpty ? departureTime : '10:00 PM',
          actualTime: departureTime.isNotEmpty ? departureTime : '10:00 PM',
          isPassed: false,
          isNext: true,
          passengerBoardingCount: b1,
          passengerDroppingCount: 0,
        ),
        RouteStop(
          id: 'stop-2',
          stopName: 'Kanpur Bypass (Rama Devi)',
          city: 'Kanpur',
          scheduledTime: '11:45 PM',
          isPassed: false,
          passengerBoardingCount: b2,
          passengerDroppingCount: 0,
        ),
        RouteStop(
          id: 'stop-3',
          stopName: 'Agra-Lucknow Expressway Toll',
          city: 'Agra',
          scheduledTime: '02:30 AM',
          isPassed: false,
          passengerBoardingCount: 0,
          passengerDroppingCount: d1,
        ),
        RouteStop(
          id: 'stop-4',
          stopName: 'Akshardham Metro Station',
          city: 'Delhi NCR',
          scheduledTime: '05:45 AM',
          isPassed: false,
          passengerBoardingCount: 0,
          passengerDroppingCount: d2,
        ),
        RouteStop(
          id: 'stop-5',
          stopName: 'Kashmere Gate ISBT',
          city: toCity,
          scheduledTime: arrivalTime.isNotEmpty ? arrivalTime : '06:30 AM',
          isPassed: false,
          passengerBoardingCount: 0,
          passengerDroppingCount: d3,
        ),
      ];
    }

    // Dynamic stops for any custom route from the API
    final halfBooked = (bookedSeats / 2).round();
    final remBooked = (bookedSeats - halfBooked).clamp(0, bookedSeats);

    return [
      RouteStop(
        id: 'stop-orig',
        stopName: '$fromCity Central Terminal',
        city: fromCity,
        scheduledTime: departureTime.isNotEmpty ? departureTime : '09:00 PM',
        actualTime: departureTime.isNotEmpty ? departureTime : '09:00 PM',
        isPassed: false,
        isNext: true,
        passengerBoardingCount: halfBooked,
        passengerDroppingCount: 0,
      ),
      RouteStop(
        id: 'stop-mid-1',
        stopName: '$fromCity Highway Bypass Hub',
        city: fromCity,
        scheduledTime: '10:30 PM',
        isPassed: false,
        passengerBoardingCount: remBooked,
        passengerDroppingCount: 0,
      ),
      RouteStop(
        id: 'stop-mid-2',
        stopName: 'En-Route Mid-way Plaza / Fuel Station',
        city: 'Midway Stop',
        scheduledTime: '01:30 AM',
        isPassed: false,
        passengerBoardingCount: 0,
        passengerDroppingCount: 0,
      ),
      RouteStop(
        id: 'stop-dest-1',
        stopName: '$toCity Ring Road Plaza',
        city: toCity,
        scheduledTime: '04:45 AM',
        isPassed: false,
        passengerBoardingCount: 0,
        passengerDroppingCount: halfBooked,
      ),
      RouteStop(
        id: 'stop-dest-main',
        stopName: '$toCity Main ISBT / Bus Port',
        city: toCity,
        scheduledTime: arrivalTime.isNotEmpty ? arrivalTime : '06:00 AM',
        isPassed: false,
        passengerBoardingCount: 0,
        passengerDroppingCount: remBooked,
      ),
    ];
  }

  Future<void> _submitStationHalt() async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final effectiveId =
        _repository.selectedTripDetails?.schedule?.id ?? _repository.activeTrip.id;

    final notes = _notesController.text.trim();

    final res = await _repository.updateTripStatusOnServer(
      tripId: effectiveId,
      status: 'halt',
      delayMinutes: _selectedMinutes,
      operationalNotes: notes.isNotEmpty ? notes : 'Station Halt at ${_selectedStop.stopName}',
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      navigator.pop();
      widget.onHaltLogged?.call();

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.pause_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.message.isNotEmpty
                      ? res.message
                      : 'Station Halt logged at ${_selectedStop.stopName}!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0E7490),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _repository.activeTrip;
    final tripDetails = _repository.selectedTripDetails;
    final activeApi = _repository.dashboardData?.activeTrip;

    final fromCity = tripDetails?.route?.sourceCity ??
        activeApi?.route?.sourceCity ??
        trip.fromCity;
    final toCity = tripDetails?.route?.destinationCity ??
        activeApi?.route?.destinationCity ??
        trip.toCity;
    final busReg = tripDetails?.bus?.registrationNumber ??
        activeApi?.bus?.registrationNumber ??
        trip.busNumber;
    final dist = (tripDetails?.route?.distanceKm != null)
        ? '${tripDetails!.route!.distanceKm} km'
        : (activeApi?.route?.distanceKm != null)
            ? '${activeApi!.route!.distanceKm} km'
            : trip.distance;
    final totalSeats = tripDetails?.seatingSummary?.totalSeats ??
        activeApi?.seating?.totalSeats ??
        _repository.totalSeats;
    final bookedSeats = tripDetails?.seatingSummary?.bookedSeatsCount ??
        activeApi?.seating?.bookedSeats ??
        _repository.bookedSeats;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E7490).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pause_circle_rounded,
                          color: Color(0xFF0E7490), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Station Halt / Intermediate Stop',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: DriverColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$fromCity ➔ $toCity • Bus: $busReg',
                            style: const TextStyle(
                              fontSize: 12,
                              color: DriverColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: DriverColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Scrollable Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Trip Summary Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CURRENT ROUTE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$fromCity ➔ $toCity',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 26, color: Colors.white24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'DISTANCE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dist,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 26, color: Colors.white24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'LOAD',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$bookedSeats/$totalSeats Seats',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFA7F3D0),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Section 1: Route Stations Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Halt Station / Stop',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: DriverColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_stops.length} Route Stops',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0E7490),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Stops List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stops.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final stop = _stops[index];
                          final isSelected = stop.id == _selectedStop.id;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedStop = stop;
                                _updateOperationalNotes();
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0E7490).withValues(alpha: 0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0E7490)
                                      : DriverColors.border,
                                  width: isSelected ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Stop index badge
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF0E7490)
                                          : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Station Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stop.stopName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? const Color(0xFF0E7490)
                                                : DriverColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              '${stop.city} • Scheduled: ${stop.scheduledTime}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: DriverColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (stop.passengerBoardingCount > 0 ||
                                            stop.passengerDroppingCount > 0) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (stop.passengerBoardingCount > 0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 1.5),
                                                  margin: const EdgeInsets.only(right: 6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFECFDF5),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                        color: const Color(0xFFA7F3D0)),
                                                  ),
                                                  child: Text(
                                                    '+${stop.passengerBoardingCount} Boarding',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF047857),
                                                    ),
                                                  ),
                                                ),
                                              if (stop.passengerDroppingCount > 0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEF3C7),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                        color: const Color(0xFFFDE68A)),
                                                  ),
                                                  child: Text(
                                                    '-${stop.passengerDroppingCount} Dropping',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFB45309),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Radio selection indicator
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: isSelected
                                        ? const Color(0xFF0E7490)
                                        : DriverColors.textMuted,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // Section 2: Halt Reason Chips
                      const Text(
                        'Reason for Station Halt',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _haltReasons.map((reason) {
                          final isSelected = _selectedReason == reason;
                          return ChoiceChip(
                            label: Text(reason),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedReason = reason;
                                  _updateOperationalNotes();
                                });
                              }
                            },
                            selectedColor: const Color(0xFF0E7490),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : DriverColors.textPrimary,
                            ),
                            backgroundColor: const Color(0xFFF8FAFC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF0E7490)
                                    : DriverColors.border,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // Section 3: Halt Duration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated Halt Duration',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: DriverColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$_selectedMinutes Minutes',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0E7490),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _durationOptions.map((mins) {
                            final isSelected = _selectedMinutes == mins;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('$mins mins'),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _selectedMinutes = mins;
                                      _updateOperationalNotes();
                                    });
                                  }
                                },
                                selectedColor: const Color(0xFF0E7490),
                                labelStyle: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : DriverColors.textPrimary,
                                ),
                                backgroundColor: const Color(0xFFF8FAFC),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF0E7490)
                                        : DriverColors.border,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Section 4: Operational Notes
                      const Text(
                        'Operational Notes (API Broadcast)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Add operational notes regarding this station halt...',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: DriverColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: DriverColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF0E7490), width: 1.5),
                          ),
                        ),
                        style: const TextStyle(fontSize: 12.5),
                      ),

                      const SizedBox(height: 14),

                      // Assigned Crew Tag
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: DriverColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_rounded,
                                size: 16, color: DriverColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Driver: ${trip.driverName} • Conductor: ${trip.conductorName}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: DriverColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitStationHalt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E7490),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.pause_circle_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Log Station Halt at ${_selectedStop.stopName}',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
