import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';

/// Interactive visual representation of a sleeper berth in the bus layout
class SleeperBerthWidget extends StatelessWidget {
  final SeatModel seat;
  final VoidCallback onTap;

  const SleeperBerthWidget({
    super.key,
    required this.seat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBooked = seat.isBooked && seat.passenger != null;
    final isUnavailable = seat.isUnavailable;
    final passenger = seat.passenger;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String statusSubtitle = '';

    if (isUnavailable) {
      bgColor = DriverColors.surfaceSecondary;
      borderColor = DriverColors.border;
      textColor = DriverColors.textMuted;
      icon = Icons.block_rounded;
      statusSubtitle = 'Blocked';
    } else if (isBooked) {
      if (passenger!.isBoarded) {
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF10B981);
        textColor = const Color(0xFF047857);
        icon = Icons.check_circle_rounded;
        statusSubtitle = passenger.boardedAt != null && passenger.boardedAt!.isNotEmpty
            ? '✓ Boarded (${passenger.boardedAt})'
            : '✓ Boarded';
      } else if (passenger.isNoShow) {
        bgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFEF4444);
        textColor = const Color(0xFFDC2626);
        icon = Icons.cancel_rounded;
        statusSubtitle = '⨂ No-Show';
      } else {
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFF59E0B);
        textColor = const Color(0xFFB45309);
        icon = Icons.person_rounded;
        statusSubtitle = 'Pending';
      }
    } else {
      bgColor = Colors.white;
      borderColor = const Color(0xFF10B981);
      textColor = const Color(0xFF047857);
      icon = Icons.single_bed_rounded;
      statusSubtitle = seat.fare != null ? '₹${seat.fare!.toStringAsFixed(0)}' : 'Vacant';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Headrest / Pillow graphic
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: textColor),
                const SizedBox(width: 4),
                Text(
                  seat.seatNumber,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ],
            ),
            if (isBooked)
              Text(
                '${passenger!.passengerName.split(' ').first} (${passenger.gender.isNotEmpty ? passenger.gender.substring(0, 1) : 'M'}/${passenger.age})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            Text(
              statusSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
