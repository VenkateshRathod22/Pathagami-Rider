import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';

/// Interactive visual seat occupancy meter with stats and progress bar
class SeatOccupancyMeter extends StatelessWidget {
  final int totalSeats;
  final int bookedSeats;
  final VoidCallback? onInspectSeats;

  const SeatOccupancyMeter({
    super.key,
    required this.totalSeats,
    required this.bookedSeats,
    this.onInspectSeats,
  });

  int get availableSeats => (totalSeats - bookedSeats).clamp(0, totalSeats);
  double get occupancyRatio => totalSeats > 0 ? (bookedSeats / totalSeats).clamp(0.0, 1.0) : 0.0;
  int get occupancyPercent => (occupancyRatio * 100).toInt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
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
              const Row(
                children: [
                  Icon(
                    Icons.event_seat_rounded,
                    color: DriverColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Bus Occupancy Status',
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
                  color: DriverColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$occupancyPercent% FULL',
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

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: occupancyRatio,
                backgroundColor: DriverColors.surfaceSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(
                  occupancyRatio >= 0.9
                      ? DriverColors.error
                      : occupancyRatio >= 0.7
                          ? DriverColors.primary
                          : DriverColors.success,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3 Columns: Total, Booked, Available
          Row(
            children: [
              Expanded(
                child: _OccupancyStatItem(
                  label: 'Total Seats',
                  value: '$totalSeats',
                  color: DriverColors.textPrimary,
                  icon: Icons.airline_seat_recline_extra_rounded,
                ),
              ),
              Container(width: 1, height: 36, color: DriverColors.border),
              Expanded(
                child: _OccupancyStatItem(
                  label: 'Booked',
                  value: '$bookedSeats',
                  color: DriverColors.primary,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              Container(width: 1, height: 36, color: DriverColors.border),
              Expanded(
                child: _OccupancyStatItem(
                  label: 'Available',
                  value: '$availableSeats',
                  color: DriverColors.success,
                  icon: Icons.airline_seat_recline_normal_rounded,
                ),
              ),
            ],
          ),

          if (onInspectSeats != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onInspectSeats,
                icon: const Icon(Icons.grid_view_rounded, size: 16),
                label: const Text('View Interactive Seat Layout'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: DriverColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OccupancyStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _OccupancyStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DriverColors.textMuted,
          ),
        ),
      ],
    );
  }
}
