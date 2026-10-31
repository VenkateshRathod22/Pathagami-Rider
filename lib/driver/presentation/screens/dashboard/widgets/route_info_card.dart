import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/status_badge.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';

/// Card presenting today's assigned route, schedule, and destination details
class RouteInfoCard extends StatelessWidget {
  final DriverTrip trip;
  final VoidCallback? onViewTripDetails;

  const RouteInfoCard({
    super.key,
    required this.trip,
    this.onViewTripDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(18),
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
                      trip.tripNumber,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trip.journeyDate,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: DriverColors.textOnDarkMuted,
                    ),
                  ),
                ],
              ),
              StatusBadge(
                label: trip.status.displayName.toUpperCase(),
                color: trip.status.color,
                isFilled: true,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Route Timeline: Origin -> Destination
          Row(
            children: [
              // Origin
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.departureTime,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.fromCity,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      trip.fromTerminal,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: DriverColors.textOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Route graphic connector
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: DriverColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: Colors.white24,
                          ),
                        ),
                        const Icon(
                          Icons.directions_bus_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: Colors.white24,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: DriverColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${trip.duration} • ${trip.distance}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: DriverColors.textOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Destination
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      trip.arrivalTime,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.toCity,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      trip.toTerminal,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 11,
                        color: DriverColors.textOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: DriverColors.borderDark, height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 16,
                    color: DriverColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${trip.bookedSeats} Passengers Booked',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (onViewTripDetails != null)
                TextButton(
                  onPressed: onViewTripDetails,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: DriverColors.accent,
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Trip Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.accent,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
