import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/widgets/passenger_details_sheet.dart';

/// Card presenting individual passenger details, PNR, seat, boarding status, and actions
class PassengerCard extends StatelessWidget {
  final PassengerBooking passenger;
  final VoidCallback onToggleBoarding;
  final VoidCallback onCallPassenger;
  final void Function(String status)? onUpdateStatus;

  const PassengerCard({
    super.key,
    required this.passenger,
    required this.onToggleBoarding,
    required this.onCallPassenger,
    this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isBoarded = passenger.isBoarded;
    final isNoShow = passenger.isNoShow;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBoarded
              ? DriverColors.success.withValues(alpha: 0.4)
              : (isNoShow ? DriverColors.brandRed.withValues(alpha: 0.4) : DriverColors.border),
          width: isBoarded || isNoShow ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            PassengerDetailsSheet.show(
              context,
              passenger: passenger,
              onUpdateStatus: onUpdateStatus,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Dark seat pill, Name, Route, and Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dark Seat Number Pill (from web screenshot)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'seat ${passenger.seatNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        passenger.seatNumber,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Name, Gender/Age, ID and PNR
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger.passengerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            '${passenger.age} yrs / ${passenger.gender}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: DriverColors.textSecondary,
                            ),
                          ),
                          const Text('•', style: TextStyle(color: DriverColors.textMuted)),
                          Text(
                            'ID: #${passenger.effectivePassengerId}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: DriverColors.primary,
                            ),
                          ),
                          const Text('•', style: TextStyle(color: DriverColors.textMuted)),
                          Text(
                            'PNR: ${passenger.pnr}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: DriverColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${passenger.pickupLocation.split(',').first.trim()} → ${passenger.dropLocation.split(',').first.trim()}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: DriverColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Pill matching web panel screenshot
                if (isNoShow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cancel_outlined, size: 14, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          'No Show',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isBoarded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF22C55E)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          passenger.boardedAt != null ? 'Boarded (${passenger.boardedAt})' : 'Boarded',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_empty_rounded, size: 13, color: Color(0xFFD97706)),
                        SizedBox(width: 4),
                        Text(
                          'Pending Check-In',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Conductor Quick Action Buttons from Web Screenshot:
            // 1. Call Button, 2. BOARDED Button, 3. NO SHOW Button
            Row(
              children: [
                // Phone Call button
                OutlinedButton.icon(
                  onPressed: onCallPassenger,
                  icon: const Icon(Icons.phone_rounded, size: 15, color: Color(0xFF10B981)),
                  label: Text(
                    passenger.phone,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const Spacer(),

                // ✓ BOARDED Action Button
                if (isBoarded)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (onUpdateStatus != null) {
                        onUpdateStatus!('pending');
                      } else {
                        onToggleBoarding();
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text('✓ BOARDED', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      if (onUpdateStatus != null) {
                        onUpdateStatus!('boarded');
                      } else {
                        onToggleBoarding();
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 14, color: Color(0xFF16A34A)),
                    label: const Text('✓ BOARDED', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800, fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Color(0xFF16A34A)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                const SizedBox(width: 8),

                // NO SHOW Action Button
                if (isNoShow)
                  ElevatedButton(
                    onPressed: () {
                      if (onUpdateStatus != null) {
                        onUpdateStatus!('pending');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('NO SHOW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                  )
                else
                  OutlinedButton(
                    onPressed: () {
                      if (onUpdateStatus != null) {
                        onUpdateStatus!('no_show');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      foregroundColor: const Color(0xFFDC2626),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('NO SHOW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}
