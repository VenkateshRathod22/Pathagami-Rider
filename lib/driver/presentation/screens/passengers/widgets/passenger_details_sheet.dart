import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/status_badge.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';

/// Modal bottom sheet displaying detailed passenger booking and ticket information
class PassengerDetailsSheet extends StatelessWidget {
  final PassengerBooking passenger;
  final void Function(String status)? onUpdateStatus;

  const PassengerDetailsSheet({
    super.key,
    required this.passenger,
    this.onUpdateStatus,
  });

  static void show(BuildContext context, {
    required PassengerBooking passenger,
    void Function(String status)? onUpdateStatus,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PassengerDetailsSheet(
        passenger: passenger,
        onUpdateStatus: onUpdateStatus,
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    await Clipboard.setData(ClipboardData(text: cleanPhone));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling $cleanPhone... (Number copied to clipboard)'),
          backgroundColor: DriverColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = DriverRepository();
    final isBoarded = passenger.isBoarded;
    final isNoShow = passenger.isNoShow;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DriverColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Header: Seat Badge & Passenger Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'seat ${passenger.seatNumber}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        passenger.isUpperDeck ? 'UPPER DECK' : 'LOWER DECK',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger.passengerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${passenger.age} Yrs • ${passenger.gender} • ID #${passenger.effectivePassengerId}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: DriverColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: isBoarded
                      ? 'BOARDED'
                      : (isNoShow ? 'NO-SHOW' : 'PENDING'),
                  color: isBoarded
                      ? DriverColors.success
                      : (isNoShow ? DriverColors.brandRed : const Color(0xFFF59E0B)),
                  isFilled: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Booking & PNR banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DriverColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DriverColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 20, color: DriverColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PNR: ${passenger.pnr}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: DriverColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Booking ID: #${passenger.effectiveBookingId.replaceAll(RegExp(r'[^0-9]'), '')}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: DriverColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: passenger.pnr));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('PNR ${passenger.pnr} copied!'),
                          backgroundColor: DriverColors.primary,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18, color: DriverColors.textSecondary),
                    tooltip: 'Copy PNR',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Route & Locations Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.alt_route_rounded, size: 16, color: DriverColors.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        'Passenger Journey Route',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Column(
                        children: [
                          Icon(Icons.circle, size: 12, color: Color(0xFF10B981)),
                          SizedBox(
                            height: 22,
                            child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 2),
                          ),
                          Icon(Icons.location_on, size: 14, color: Color(0xFFEF4444)),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              passenger.pickupLocation,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: DriverColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Scheduled Pickup: ${passenger.pickupTime}',
                              style: const TextStyle(fontSize: 11, color: DriverColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              passenger.dropLocation,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: DriverColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Estimated Drop: ${passenger.dropTime}',
                              style: const TextStyle(fontSize: 11, color: DriverColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Fare & Payment Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ticket Fare', style: TextStyle(fontSize: 11, color: Color(0xFF15803D))),
                        const SizedBox(height: 2),
                        Text(
                          '₹${passenger.fare.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Status', style: TextStyle(fontSize: 11, color: Color(0xFF1D4ED8))),
                        const SizedBox(height: 2),
                        Text(
                          passenger.paymentStatus.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E40AF),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Phone Contact row with Call button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DriverColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Passenger Phone', style: TextStyle(fontSize: 11, color: DriverColors.textSecondary)),
                        Text(
                          passenger.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: DriverColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(context, passenger.phone),
                    icon: const Icon(Icons.phone, size: 15),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Assigned Crew info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Driver: ${repo.driverName}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: DriverColors.textSecondary),
                  ),
                  Text(
                    'Conductor: ${repo.conductorName}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: DriverColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Conductor Actions: Mark as Boarded / No-Show / Undo
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      final target = isBoarded ? 'pending' : 'boarded';
                      if (onUpdateStatus != null) {
                        onUpdateStatus!(target);
                      } else {
                        repo.confirmPassengerBoardingOnServer(
                          passengerId: passenger.effectivePassengerId,
                          status: target,
                          pnr: passenger.pnr,
                        );
                      }
                    },
                    icon: Icon(isBoarded ? Icons.undo_rounded : Icons.check_circle_rounded, size: 18),
                    label: Text(isBoarded ? 'Undo Boarding' : 'Mark as Boarded'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBoarded ? DriverColors.surfaceSecondary : const Color(0xFF16A34A),
                      foregroundColor: isBoarded ? DriverColors.textPrimary : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      final target = isNoShow ? 'pending' : 'no_show';
                      if (onUpdateStatus != null) {
                        onUpdateStatus!(target);
                      } else {
                        repo.confirmPassengerBoardingOnServer(
                          passengerId: passenger.effectivePassengerId,
                          status: target,
                          pnr: passenger.pnr,
                        );
                      }
                    },
                    icon: Icon(isNoShow ? Icons.undo_rounded : Icons.cancel_outlined, size: 18),
                    label: Text(isNoShow ? 'Reset Status' : 'Mark No-Show'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isNoShow ? DriverColors.border : const Color(0xFFDC2626)),
                      foregroundColor: isNoShow ? DriverColors.textPrimary : const Color(0xFFDC2626),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Close button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close Details', style: TextStyle(color: DriverColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
