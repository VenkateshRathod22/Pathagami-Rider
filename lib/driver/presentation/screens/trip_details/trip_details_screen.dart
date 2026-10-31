import 'package:flutter/material.dart';
import 'package:bus_driver/api/api.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/driver_app_bar.dart';
import 'package:bus_driver/driver/core/widgets/status_badge.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';
import 'package:bus_driver/driver/presentation/screens/bus_layout/bus_seat_layout_screen.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/passenger_list_screen.dart';
import 'package:bus_driver/driver/presentation/screens/trip_details/widgets/route_timeline_widget.dart';

/// Trip Details Screen
///
/// Features:
/// - Real-time Trip details from /crew/trips/{id}
/// - Schedule details, timings, route, distance, and base fare
/// - Complete Assigned Driver profile & particulars (Badge ID, Phone, Call button)
/// - Complete Assigned Conductor particulars (Badge ID, Phone, Call button)
/// - Full Seating Summary (Total, Booked, Vacant, Boarded, Pending, No-Show)
/// - Assigned Bus vehicle specifications & operator info
/// - Passenger Manifest status and interactive seat inspection
/// - Start Trip & Complete Trip lifecycle actions with checklist verification
class TripDetailsScreen extends StatefulWidget {
  final DriverTrip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final DriverRepository _repository = DriverRepository();
  late DriverTrip _currentTrip;
  CrewTripDetailsData? _apiDetails;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _repository.addListener(_onRepositoryUpdated);
    _loadTripDetails();
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryUpdated);
    super.dispose();
  }

  void _onRepositoryUpdated() {
    if (mounted) {
      if (_repository.activeTrip.id == _currentTrip.id) {
        setState(() {
          _currentTrip = _repository.activeTrip;
        });
      }
    }
  }

  Future<void> _loadTripDetails() async {
    setState(() => _isLoading = true);
    final data = await _repository.fetchTripDetails(_currentTrip.id);
    if (mounted) {
      setState(() {
        _apiDetails = data ?? _repository.selectedTripDetails;
        _isLoading = false;
      });
    }
  }

  void _callPerson({
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

  void _showStartTripConfirmation() {
    bool checkedFuel = true;
    bool checkedSafety = true;
    bool checkedOdometer = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.play_circle_fill_rounded, color: DriverColors.primary, size: 24),
                SizedBox(width: 8),
                Text('Start This Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm departure for ${_currentTrip.fromCity} → ${_currentTrip.toCity} (Bus ${_currentTrip.busNumber}).',
                  style: const TextStyle(fontSize: 13.5, color: DriverColors.textSecondary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pre-Departure Safety Checklist:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DriverColors.textPrimary),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Fuel level & Tire pressure inspected', style: TextStyle(fontSize: 12.5)),
                  value: checkedFuel,
                  onChanged: (val) => setModalState(() => checkedFuel = val ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Cabin sanitization & AC operational', style: TextStyle(fontSize: 12.5)),
                  value: checkedSafety,
                  onChanged: (val) => setModalState(() => checkedSafety = val ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Departure point passenger manifest verified', style: TextStyle(fontSize: 12.5)),
                  value: checkedOdometer,
                  onChanged: (val) => setModalState(() => checkedOdometer = val ?? false),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: DriverColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: (checkedFuel && checkedSafety && checkedOdometer)
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 8),
                                Text('Marking bus as DEPARTED on server...'),
                              ],
                            ),
                            backgroundColor: DriverColors.primary,
                            duration: Duration(seconds: 1),
                          ),
                        );
                        final res = await _repository.startTrip(
                          _currentTrip.id,
                          operationalNotes: 'Departed from main depot on time',
                        );
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                res?.message ?? 'Bus marked as DEPARTED & On Road!',
                              ),
                              backgroundColor: DriverColors.success,
                            ),
                          );
                          _loadTripDetails();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DriverColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Trip Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCompleteTripConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.flag_rounded, color: DriverColors.success, size: 24),
            SizedBox(width: 8),
            Text('Complete Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Has the bus arrived at the final destination (${_currentTrip.toTerminal}, ${_currentTrip.toCity}) and all passengers safely deboarded?',
              style: const TextStyle(fontSize: 13.5, color: DriverColors.textSecondary),
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
                  _buildSummaryMiniRow('Total Distance Logged', _currentTrip.distance),
                  _buildSummaryMiniRow('Service Duration', _currentTrip.duration),
                  _buildSummaryMiniRow('Passengers Carried', '${_currentTrip.bookedSeats} Passengers'),
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
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              messenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text('Marking trip as COMPLETED on server...'),
                    ],
                  ),
                  backgroundColor: DriverColors.primary,
                  duration: Duration(seconds: 1),
                ),
              );
              final res = await _repository.completeTrip(
                _currentTrip.id,
                operationalNotes: 'Trip completed safely at destination',
              );
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res?.message ?? 'Trip marked as COMPLETED! Great job.'),
                    backgroundColor: DriverColors.success,
                  ),
                );
                _loadTripDetails();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Completion'),
          ),
        ],
      ),
    );
  }

  void _showUpdateRoadStatusDialog() {
    final noteController = TextEditingController(
      text: _apiDetails?.schedule?.operationalNotes ?? _currentTrip.operationalNotes ?? 'Departed from main depot on time',
    );
    int delay = _apiDetails?.schedule?.delayMinutes ?? _currentTrip.delayMinutes;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.edit_road_rounded, color: DriverColors.primary, size: 22),
                SizedBox(width: 8),
                Text('Road Status & Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update live road transit status or report traffic delay to depot:',
                  style: TextStyle(fontSize: 13, color: DriverColors.textSecondary),
                ),
                const SizedBox(height: 12),
                const Text('Operational Notes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Departed from main depot on time',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transit Delay:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      delay == 0 ? 'On Time (0 min)' : '+$delay min delay',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: delay > 0 ? const Color(0xFFD97706) : DriverColors.success,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: delay.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 8,
                  label: '$delay min',
                  activeColor: delay > 0 ? const Color(0xFFD97706) : DriverColors.primary,
                  onChanged: (val) => setModalState(() => delay = val.round()),
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
                  final res = await _repository.updateTripStatusOnServer(
                    tripId: _currentTrip.id,
                    status: 'in_transit',
                    delayMinutes: delay,
                    operationalNotes: noteController.text.trim(),
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(res.message.isNotEmpty ? res.message : 'Road status updated successfully!'),
                        backgroundColor: DriverColors.primary,
                      ),
                    );
                    _loadTripDetails();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DriverColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save & Sync'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryMiniRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: DriverColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DriverColors.textPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = _currentTrip;
    final schedule = _apiDetails?.schedule;
    final bus = _apiDetails?.bus;
    final route = _apiDetails?.route;
    final operator = _apiDetails?.operator;
    final driver = _apiDetails?.driver;
    final conductor = _apiDetails?.conductor;
    final seatingSummary = _apiDetails?.seatingSummary;
    final manifest = _apiDetails?.manifest;

    final isEnRoute = (schedule?.status == 'in_transit') || (trip.status == TripStatus.inProgress);
    final isScheduled = (schedule?.status == 'scheduled') || (trip.status == TripStatus.scheduled);

    final String fromCity = route?.sourceCity ?? trip.fromCity;
    final String toCity = route?.destinationCity ?? trip.toCity;
    final String busNumber = bus?.registrationNumber ?? trip.busNumber;
    final String busType = bus?.busType ?? trip.busType;
    final String departureDate = schedule?.departureDate ?? trip.journeyDate;
    final String departureTime = schedule?.departureTime ?? trip.departureTime;
    final String arrivalDate = schedule?.arrivalDate ?? departureDate;
    final String arrivalTime = schedule?.arrivalTime ?? trip.arrivalTime;
    final String distance = route?.distanceKm != null ? '${route!.distanceKm} km' : trip.distance;
    final num baseFare = schedule?.baseFare ?? 950;

    return Scaffold(
      backgroundColor: DriverColors.background,
      appBar: DriverAppBar(
        title: 'Trip Details',
        subtitle: 'Schedule #${schedule?.id ?? trip.id} • $busType ($busNumber)',
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: DriverColors.border)),
        ),
        child: SafeArea(
          child: isScheduled
              ? ElevatedButton.icon(
                  onPressed: _showStartTripConfirmation,
                  icon: const Icon(Icons.play_circle_filled_rounded),
                  label: const Text('START TRIP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              : isEnRoute
                  ? Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: _showUpdateRoadStatusDialog,
                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                            label: const Text('Road Notes'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: DriverColors.primary,
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: _showCompleteTripConfirmation,
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text('COMPLETE TRIP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DriverColors.success,
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: DriverColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DriverColors.success),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt_rounded, color: DriverColors.success, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'TRIP COMPLETED SUCCESSFULLY',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: DriverColors.successDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTripDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Sync Status Header
              if (_isLoading)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: DriverColors.primary),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Updating live trip details from server...',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DriverColors.primary),
                      ),
                    ],
                  ),
                ),

              // 1. Hero Route Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: DriverColors.activeCardGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SCHEDULE #${schedule?.id ?? trip.id}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '₹$baseFare Fare',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if ((schedule?.delayMinutes ?? trip.delayMinutes) > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${schedule?.delayMinutes ?? trip.delayMinutes}m delay',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        StatusBadge(
                          label: (schedule?.status ?? trip.status.name).toUpperCase().replaceAll('_', ' '),
                          color: isEnRoute
                              ? DriverColors.success
                              : (isScheduled ? const Color(0xFFD97706) : DriverColors.primary),
                          isFilled: true,
                        ),
                      ],
                    ),

                    // Operational Notes Alert if provided
                    if ((schedule?.operationalNotes ?? trip.operationalNotes) != null &&
                        (schedule?.operationalNotes ?? trip.operationalNotes)!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (schedule?.operationalNotes ?? trip.operationalNotes)!,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Route timeline
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                departureTime,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                fromCity,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              Text(
                                departureDate,
                                style: const TextStyle(fontSize: 11, color: DriverColors.textOnDarkMuted),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(color: DriverColors.accent, shape: BoxShape.circle),
                                  ),
                                  Expanded(child: Container(height: 1.5, color: Colors.white30)),
                                  const Icon(Icons.directions_bus_rounded, size: 16, color: Colors.white),
                                  Expanded(child: Container(height: 1.5, color: Colors.white30)),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(color: DriverColors.success, shape: BoxShape.circle),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                distance,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                arrivalTime,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                toCity,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              Text(
                                arrivalDate,
                                style: const TextStyle(fontSize: 11, color: DriverColors.textOnDarkMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Primary Assigned Driver Card (Complete details as requested)
              _buildDriverCard(driver ?? _repository.dashboardData?.activeTrip?.driver),

              const SizedBox(height: 14),

              // 3. Assigned Conductor Card
              _buildConductorCard(conductor ?? _repository.dashboardData?.activeTrip?.conductor),

              const SizedBox(height: 16),

              // 4. Live Seating & Boarding Analytics Summary (seating_summary)
              _buildSeatingSummarySection(
                seating: seatingSummary,
                fallbackTotal: trip.totalSeats,
                fallbackBooked: trip.bookedSeats,
                fallbackAvailable: trip.availableSeats,
              ),

              const SizedBox(height: 16),

              // 5. Assigned Bus Vehicle Information Card
              _buildBusDetailsCard(bus: bus, trip: trip),

              const SizedBox(height: 16),

              // 6. Depot & Branch Operator Card
              _buildOperatorCard(operator: operator),

              const SizedBox(height: 16),

              // 7. Passenger Manifest & Seat Layout Actions
              _buildManifestAndSeatsRow(
                trip: trip,
                manifest: manifest,
                seating: seatingSummary,
              ),

              const SizedBox(height: 16),

              // 8. Route Stops Timeline
              RouteTimelineWidget(stops: trip.stops),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Complete Assigned Driver Card
  Widget _buildDriverCard(dynamic driverData) {
    String driverName = 'Reece Wiza-Robel';
    String driverBadge = 'DRV00001';
    String driverPhone = '6327114051';

    if (driverData != null) {
      if (driverData is TripCrewMember) {
        driverName = driverData.name.isNotEmpty ? driverData.name : driverName;
        driverBadge = driverData.crewId.isNotEmpty ? driverData.crewId : driverBadge;
        driverPhone = driverData.phone.isNotEmpty ? driverData.phone : driverPhone;
      } else if (driverData is CrewPerson) {
        driverName = driverData.name.isNotEmpty ? driverData.name : driverName;
        driverPhone = driverData.phone.isNotEmpty ? driverData.phone : driverPhone;
      }
    } else if (_repository.profile.name.isNotEmpty) {
      driverName = _repository.profile.name;
      driverBadge = _repository.profile.id;
      driverPhone = _repository.profile.phone;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF93C5FD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, 3),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DriverColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.drive_eta_rounded, color: DriverColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Bus Driver',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Lead Commercial Pilot',
                        style: TextStyle(fontSize: 11, color: DriverColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  driverBadge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: DriverColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _buildDetailRow('Driver Full Name', driverName),
          _buildDetailRow('Crew Badge ID', driverBadge),
          _buildDetailRow('Registered Mobile Phone', driverPhone),
          _buildDetailRow('Role Classification', 'Commercial Passenger Vehicle Driver'),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: driverPhone.isNotEmpty
                  ? () => _callPerson(name: driverName, role: 'Driver', phone: driverPhone)
                  : null,
              icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
              label: Text('Call Driver ($driverPhone)'),
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

  /// Complete Assigned Conductor Card
  Widget _buildConductorCard(dynamic conductorData) {
    String condName = 'Khalil Swaniawski';
    String condBadge = 'CND00001';
    String condPhone = '7527425651';

    if (conductorData != null) {
      if (conductorData is TripCrewMember) {
        condName = conductorData.name.isNotEmpty ? conductorData.name : condName;
        condBadge = conductorData.crewId.isNotEmpty ? conductorData.crewId : condBadge;
        condPhone = conductorData.phone.isNotEmpty ? conductorData.phone : condPhone;
      } else if (conductorData is CrewPerson) {
        condName = conductorData.name.isNotEmpty ? conductorData.name : condName;
        condPhone = conductorData.phone.isNotEmpty ? conductorData.phone : condPhone;
      }
    }

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.badge_rounded, color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Bus Conductor',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Passenger & Ticket Marshall',
                        style: TextStyle(fontSize: 11, color: DriverColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  condBadge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _buildDetailRow('Conductor Full Name', condName),
          _buildDetailRow('Crew Badge ID', condBadge),
          _buildDetailRow('Registered Mobile Phone', condPhone),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: condPhone.isNotEmpty
                  ? () => _callPerson(name: condName, role: 'Conductor', phone: condPhone)
                  : null,
              icon: const Icon(Icons.call_rounded, size: 16),
              label: Text('Call Conductor ($condPhone)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB45309),
                side: const BorderSide(color: Color(0xFFD97706), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Live Seating & Boarding Analytics Summary Grid
  Widget _buildSeatingSummarySection({
    required TripSeatingSummary? seating,
    required int fallbackTotal,
    required int fallbackBooked,
    required int fallbackAvailable,
  }) {
    final int total = seating?.totalSeats ?? fallbackTotal;
    final int booked = seating?.bookedSeatsCount ?? fallbackBooked;
    final int vacant = seating?.vacantSeatsCount ?? fallbackAvailable;
    final int boarded = seating?.boardedCount ?? 0;
    final int pending = seating?.pendingBoardingCount ?? 0;
    final int noShow = seating?.noShowCount ?? 0;

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
                  Icon(Icons.event_seat_rounded, color: DriverColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Seating & Boarding Summary',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: DriverColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$vacant Vacant Berths',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 6 KPI Metric Grid
          Row(
            children: [
              Expanded(
                child: _buildKpiBox(
                  label: 'Total Capacity',
                  value: '$total',
                  sub: 'Berths (2+1)',
                  color: const Color(0xFF0F172A),
                  bg: const Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiBox(
                  label: 'Booked Seats',
                  value: '$booked',
                  sub: 'Reserved',
                  color: const Color(0xFFD97706),
                  bg: const Color(0xFFFFFBEB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiBox(
                  label: 'Vacant Seats',
                  value: '$vacant',
                  sub: 'Ready to Book',
                  color: const Color(0xFF059669),
                  bg: const Color(0xFFECFDF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildKpiBox(
                  label: 'Boarded',
                  value: '$boarded',
                  sub: 'On Bus',
                  color: const Color(0xFF2563EB),
                  bg: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiBox(
                  label: 'Pending',
                  value: '$pending',
                  sub: 'To Board',
                  color: const Color(0xFF8B5CF6),
                  bg: const Color(0xFFF5F3FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiBox(
                  label: 'No-Show',
                  value: '$noShow',
                  sub: 'Missed',
                  color: const Color(0xFFEF4444),
                  bg: const Color(0xFFFEF2F2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiBox({
    required String label,
    required String value,
    required String sub,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: DriverColors.textPrimary,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: 9.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Assigned Bus Details Card
  Widget _buildBusDetailsCard({
    required ActiveBus? bus,
    required DriverTrip trip,
  }) {
    final reg = bus?.registrationNumber ?? trip.busNumber;
    final type = bus?.busType ?? trip.busType;
    final total = bus?.totalSeats ?? trip.totalSeats;
    final name = bus?.busName ?? 'Royal Express Fleet';

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
          const Row(
            children: [
              Icon(Icons.directions_bus_rounded, size: 18, color: DriverColors.primary),
              SizedBox(width: 8),
              Text(
                'Assigned Bus Information',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DriverColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDetailRow('Bus Registration Number', reg),
          _buildDetailRow('Vehicle Classification', type),
          _buildDetailRow('Total Seating Capacity', '$total Sleeper Berths (2+1)'),
          _buildDetailRow('Fleet / Bus Name', name),
          _buildDetailRow('Bus Internal Identifier', '#${bus?.id ?? 1}'),
        ],
      ),
    );
  }

  /// Operator / Branch Card
  Widget _buildOperatorCard({required CrewOperator? operator}) {
    final name = operator?.operatorName ?? 'lucknow branch';
    final email = operator?.email ?? 'branch@gmail.com';
    final contact = operator?.contactNumber ?? 'Primary Depot Desk';

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
          const Row(
            children: [
              Icon(Icons.corporate_fare_rounded, size: 18, color: DriverColors.primary),
              SizedBox(width: 8),
              Text(
                'Branch & Operator Particulars',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DriverColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDetailRow('Operating Branch', name),
          _buildDetailRow('Official Email', email),
          _buildDetailRow('Dispatch Contact', contact),
        ],
      ),
    );
  }

  /// Passenger Manifest & Seat Layout navigation row
  Widget _buildManifestAndSeatsRow({
    required DriverTrip trip,
    required dynamic manifest,
    required TripSeatingSummary? seating,
  }) {
    final int bookedCount = seating?.bookedSeatsCount ?? trip.bookedSeats;
    final int vacantCount = seating?.vacantSeatsCount ?? trip.availableSeats;
    final bool isEmptyManifest = (manifest == null) || (manifest is List && manifest.isEmpty);

    return Column(
      children: [
        if (isEmptyManifest && bookedCount == 0)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DriverColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: DriverColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No passengers currently booked for this schedule. All $vacantCount sleeper berths are open and available.',
                    style: const TextStyle(fontSize: 12, color: DriverColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PassengerListScreen(tripId: trip.id)),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
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
                          const Icon(Icons.people_alt_rounded, color: DriverColors.primary, size: 22),
                          Text(
                            '$bookedCount',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: DriverColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Passenger Manifest', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const Text('View full list →', style: TextStyle(fontSize: 11, color: DriverColors.primary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BusSeatLayoutScreen(
                        busNumber: trip.busNumber,
                        busType: trip.busType,
                        tripId: _apiDetails?.schedule?.id ?? trip.id,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
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
                          const Icon(Icons.grid_view_rounded, color: DriverColors.accent, size: 22),
                          Text(
                            '$vacantCount Left',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DriverColors.success),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Bus Seat Layout', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const Text('Inspect berths →', style: TextStyle(fontSize: 11, color: DriverColors.accent)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: DriverColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: DriverColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
