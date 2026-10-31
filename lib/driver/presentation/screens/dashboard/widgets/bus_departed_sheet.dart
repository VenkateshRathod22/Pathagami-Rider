import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';

/// Modal bottom sheet for confirming Bus Departure and marking status as In Transit / On Road.
/// Displays departure station names, scheduled timings, passenger counts, bus details,
/// and customizable operational notes sent to POST /crew/trips/{id}/status.
class BusDepartedSheet extends StatefulWidget {
  final VoidCallback? onDepartedLogged;

  const BusDepartedSheet({super.key, this.onDepartedLogged});

  static Future<void> show(BuildContext context, {VoidCallback? onDepartedLogged}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BusDepartedSheet(onDepartedLogged: onDepartedLogged),
    );
  }

  @override
  State<BusDepartedSheet> createState() => _BusDepartedSheetState();
}

class _BusDepartedSheetState extends State<BusDepartedSheet> {
  final DriverRepository _repository = DriverRepository();
  late TextEditingController _notesController;

  late List<RouteStop> _stops;
  late RouteStop _selectedDepartureStop;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _stops = _repository.activeTrip.stops.isNotEmpty
        ? _repository.activeTrip.stops
        : _getDefaultStops();

    // Default to origin stop (first stop) or next unpassed stop
    _selectedDepartureStop = _stops.first;

    _notesController = TextEditingController();
    _updateOperationalNotes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateOperationalNotes() {
    _notesController.text =
        'Departed from ${_selectedDepartureStop.stopName} on time';
  }

  List<RouteStop> _getDefaultStops() {
    return const [
      RouteStop(
        id: 'stop-1',
        stopName: 'Alambagh Bus Terminal',
        city: 'Lucknow',
        scheduledTime: '10:00 PM',
        actualTime: '10:00 PM',
        isPassed: false,
        isNext: true,
        passengerBoardingCount: 16,
        passengerDroppingCount: 0,
      ),
      RouteStop(
        id: 'stop-2',
        stopName: 'Kanpur Bypass (Rama Devi)',
        city: 'Kanpur',
        scheduledTime: '11:45 PM',
        isPassed: false,
        passengerBoardingCount: 8,
        passengerDroppingCount: 0,
      ),
      RouteStop(
        id: 'stop-3',
        stopName: 'Agra-Lucknow Expressway Toll',
        city: 'Agra',
        scheduledTime: '02:30 AM',
        isPassed: false,
        passengerBoardingCount: 0,
        passengerDroppingCount: 2,
      ),
      RouteStop(
        id: 'stop-4',
        stopName: 'Akshardham Metro Station',
        city: 'Delhi NCR',
        scheduledTime: '05:45 AM',
        isPassed: false,
        passengerBoardingCount: 0,
        passengerDroppingCount: 8,
      ),
      RouteStop(
        id: 'stop-5',
        stopName: 'Kashmere Gate ISBT',
        city: 'New Delhi',
        scheduledTime: '06:30 AM',
        isPassed: false,
        passengerBoardingCount: 0,
        passengerDroppingCount: 14,
      ),
    ];
  }

  Future<void> _submitBusDeparted() async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final effectiveId =
        _repository.selectedTripDetails?.schedule?.id ?? _repository.activeTrip.id;

    final notes = _notesController.text.trim();

    final res = await _repository.updateTripStatusOnServer(
      tripId: effectiveId,
      status: 'in_transit',
      delayMinutes: 0,
      operationalNotes: notes.isNotEmpty
          ? notes
          : 'Departed from ${_selectedDepartureStop.stopName} on time',
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      navigator.pop();
      widget.onDepartedLogged?.call();

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.message.isNotEmpty
                      ? res.message
                      : 'Bus marked as DEPARTED & On Road from ${_selectedDepartureStop.stopName}!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1D4ED8),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _repository.activeTrip;
    final apiDetails = _repository.selectedTripDetails;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final departureDate = apiDetails?.schedule?.departureDate ?? trip.journeyDate;
    final departureTime = apiDetails?.schedule?.departureTime ?? trip.departureTime;
    final arrivalTime = apiDetails?.schedule?.arrivalTime ?? trip.arrivalTime;
    final baseFare = apiDetails?.schedule?.baseFare ?? 950;
    final regNumber = apiDetails?.bus?.registrationNumber ?? trip.busNumber;

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
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_bus_rounded,
                          color: Color(0xFF1D4ED8), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bus Departed & On Road',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: DriverColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${trip.fromCity} ➔ ${trip.toCity} • Bus: $regNumber',
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

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Schedule & Route Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x281D4ED8),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SCHEDULED DEPARTURE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFBFDBFE),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      departureTime,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      departureDate,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFFDBEAFE),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(width: 1, height: 36, color: Colors.white24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'EST. ARRIVAL',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFBFDBFE),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      arrivalTime,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${trip.distance} • 7.5 hrs',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFFDBEAFE),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(width: 1, height: 36, color: Colors.white24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'BASE FARE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFBFDBFE),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹$baseFare',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFFDE047),
                                      ),
                                    ),
                                    Text(
                                      '${_repository.bookedSeats}/${_repository.totalSeats} Seats',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFFDBEAFE),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Section 1: Select Departure Station
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Departure Station',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: DriverColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Origin & Route Stops',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Stations List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stops.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final stop = _stops[index];
                          final isSelected = stop.id == _selectedDepartureStop.id;
                          final isOrigin = index == 0;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDepartureStop = stop;
                                _updateOperationalNotes();
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1D4ED8).withValues(alpha: 0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1D4ED8)
                                      : DriverColors.border,
                                  width: isSelected ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Station badge / icon
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF1D4ED8)
                                          : (isOrigin
                                              ? const Color(0xFFECFDF5)
                                              : const Color(0xFFF1F5F9)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: isSelected
                                          ? const Icon(Icons.check_rounded,
                                              size: 16, color: Colors.white)
                                          : Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isOrigin
                                                    ? const Color(0xFF047857)
                                                    : Colors.black87,
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                stop.stopName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: isSelected
                                                      ? const Color(0xFF1D4ED8)
                                                      : DriverColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (isOrigin)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'ORIGIN DEPOT',
                                                  style: TextStyle(
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF047857),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${stop.city} • Scheduled Departure: ${stop.scheduledTime}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: DriverColors.textSecondary,
                                          ),
                                        ),
                                        if (stop.passengerBoardingCount > 0) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '👥 ${stop.passengerBoardingCount} Passengers boarding at this station',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF047857),
                                            ),
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
                                        ? const Color(0xFF1D4ED8)
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

                      // Section 2: Operational Notes for Dispatch
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
                          hintText: 'Add operational notes regarding departure...',
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
                            borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
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
                            const Icon(Icons.badge_rounded, size: 16, color: DriverColors.primary),
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
                    onPressed: _isSubmitting ? null : _submitBusDeparted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
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
                              const Icon(Icons.directions_bus_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Confirm Departure from ${_selectedDepartureStop.stopName}',
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
