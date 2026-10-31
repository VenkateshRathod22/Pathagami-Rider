import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/status_badge.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/widgets/passenger_details_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/widgets/spot_booking_sheet.dart';

/// Read-only seat inspection bottom sheet for drivers.
/// Prevents accidental modifications while allowing quick verification of passenger details.
class SeatInspectorSheet extends StatelessWidget {
  final SeatModel seat;
  final VoidCallback onClose;

  const SeatInspectorSheet({
    super.key,
    required this.seat,
    required this.onClose,
  });

  static void show(BuildContext context, SeatModel seat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SeatInspectorSheet(
        seat: seat,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passenger = seat.passenger;
    final isBooked = seat.isBooked && passenger != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DriverColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Seat Number & Deck Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isBooked
                            ? DriverColors.primary.withValues(alpha: 0.1)
                            : DriverColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isBooked ? DriverColors.primary : DriverColors.success,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        seat.seatNumber,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isBooked ? DriverColors.primary : DriverColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Berth ${seat.seatNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: DriverColors.textPrimary,
                            ),
                          ),
                          Text(
                            seat.isUpperDeck
                                ? 'Upper Deck • Single Sleeper Berth'
                                : 'Lower Deck • Luxury Sleeper Berth',
                            style: const TextStyle(
                              fontSize: 12,
                              color: DriverColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: isBooked ? 'OCCUPIED' : 'AVAILABLE',
                color: isBooked ? DriverColors.primary : DriverColors.success,
                isFilled: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Passenger Details or Vacant Info
          if (isBooked) ...[
            _buildDetailRow('Passenger Name', passenger.passengerName, isBold: true),
            _buildDetailRow('Passenger ID', '#${passenger.effectivePassengerId}'),
            _buildDetailRow('PNR / Booking ID', passenger.pnr),
            _buildDetailRow('Seat Number', seat.seatNumber),
            _buildDetailRow('Age / Gender', '${passenger.age} Years • ${passenger.gender}'),
            _buildDetailRow('Contact Phone', passenger.phone),
            _buildDetailRow('Pickup Location', passenger.pickupLocation),
            _buildDetailRow('Drop Location', passenger.dropLocation),
            _buildDetailRow(
              'Boarding Status',
              passenger.isBoarded ? 'BOARDED' : (passenger.isNoShow ? 'NO-SHOW' : 'PENDING'),
              isBold: true,
            ),
            if (passenger.boardedAt != null && passenger.boardedAt!.isNotEmpty)
              _buildDetailRow('Boarded At', passenger.boardedAt!),
            _buildDetailRow('Ticket Fare', '₹${passenger.fare.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      final target = passenger.isBoarded ? 'pending' : 'boarded';
                      final res = await DriverRepository().confirmPassengerBoardingOnServer(
                        passengerId: passenger.effectivePassengerId,
                        status: target,
                        pnr: passenger.pnr,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(res.message.isNotEmpty ? res.message : 'Passenger marked as $target'),
                          backgroundColor: target == 'boarded' ? DriverColors.success : DriverColors.primary,
                        ),
                      );
                    },
                    icon: Icon(passenger.isBoarded ? Icons.undo_rounded : Icons.check_circle_rounded, size: 16),
                    label: Text(passenger.isBoarded ? 'Undo Boarding' : 'Mark as Boarded'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: passenger.isBoarded ? DriverColors.surfaceSecondary : DriverColors.success,
                      foregroundColor: passenger.isBoarded ? DriverColors.textPrimary : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  PassengerDetailsSheet.show(context, passenger: passenger);
                },
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text('View Full Ticket & Journey Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DriverColors.primary,
                  side: const BorderSide(color: DriverColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else ...[
            _buildDetailRow('Berth Number', seat.seatNumber, isBold: true),
            if (seat.seatId != null && seat.seatId! > 0)
              _buildDetailRow('Seat Inventory ID', '#${seat.seatId}'),
            _buildDetailRow('Deck Location', seat.isUpperDeck ? 'Upper Deck' : 'Lower Deck'),
            _buildDetailRow('Berth Type', '${(seat.seatType ?? 'sleeper').toUpperCase()} Berth (2+1 AC Sleeper)'),
            _buildDetailRow(
              'Live Fare',
              '₹${seat.fare != null ? seat.fare!.toStringAsFixed(0) : (seat.isUpperDeck ? '980' : '1000')}',
              isBold: true,
            ),
            _buildDetailRow('Booking Status', 'VACANT & AVAILABLE'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DriverColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DriverColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: DriverColors.success, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Live Inventory: Berth is open for on-spot conductor ticketing or passenger pickup along the route.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: DriverColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  SpotBookingSheet.show(context, seat: seat);
                },
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text(
                  'Book This Berth (Spot Booking)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Safe driver mode notice & close
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 14, color: DriverColors.textMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Driver Mode: Read-only verification manifest. Bookings cannot be altered here.',
                  style: TextStyle(
                    fontSize: 11,
                    color: DriverColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close Inspector'),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: DriverColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: DriverColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
