import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';

/// Vertical timeline displaying journey milestone stops, departure/arrival timings, and passenger counts
class RouteTimelineWidget extends StatelessWidget {
  final List<RouteStop> stops;

  const RouteTimelineWidget({super.key, required this.stops});

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DriverColors.border),
        ),
        child: const Center(
          child: Text(
            'Direct point-to-point non-stop route.',
            style: TextStyle(color: DriverColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: DriverColors.primary),
              SizedBox(width: 8),
              Text(
                'Route Stops & Timings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: DriverColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stops.length,
            itemBuilder: (context, index) {
              final stop = stops[index];
              final isFirst = index == 0;
              final isLast = index == stops.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Node
                    Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFirst
                                ? DriverColors.accent
                                : isLast
                                    ? DriverColors.success
                                    : stop.isPassed
                                        ? DriverColors.success
                                        : Colors.white,
                            border: Border.all(
                              color: isFirst
                                  ? DriverColors.accent
                                  : isLast
                                      ? DriverColors.success
                                      : DriverColors.primary,
                              width: 2.5,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: stop.isPassed ? DriverColors.success : DriverColors.border,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Stop Information
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  stop.scheduledTime,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: stop.isPassed ? DriverColors.textMuted : DriverColors.primary,
                                  ),
                                ),
                                if (isFirst)
                                  _buildTag('ORIGIN', DriverColors.accent)
                                else if (isLast)
                                  _buildTag('DESTINATION', DriverColors.success)
                                else if (stop.passengerBoardingCount > 0)
                                  _buildTag('+${stop.passengerBoardingCount} Boarding', DriverColors.warningDark)
                                else if (stop.passengerDroppingCount > 0)
                                  _buildTag('-${stop.passengerDroppingCount} Drop', DriverColors.info),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stop.stopName,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: stop.isPassed ? DriverColors.textMuted : DriverColors.textPrimary,
                              ),
                            ),
                            Text(
                              stop.city,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: DriverColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
