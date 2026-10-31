import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/status_badge.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';

/// Interactive card presenting a trip's route, timings, bus, and status
class TripCard extends StatelessWidget {
  final DriverTrip trip;
  final VoidCallback onTap;
  final VoidCallback? onQuickAction;
  final String? quickActionLabel;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.onQuickAction,
    this.quickActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isEnRoute = trip.status == TripStatus.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnRoute ? DriverColors.success : DriverColors.border,
          width: isEnRoute ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isEnRoute ? const Color(0x1810B981) : const Color(0x0A000000),
            blurRadius: isEnRoute ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Trip ID, Bus Number & Type, Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: DriverColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            trip.tripNumber,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: DriverColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          trip.busNumber,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DriverColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: DriverColors.border),
                          ),
                          child: Text(
                            trip.busType,
                            style: const TextStyle(
                              fontSize: 10,
                              color: DriverColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (trip.delayMinutes > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Text(
                              '+${trip.delayMinutes}m delay',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: trip.status.displayName,
                    color: trip.status.color,
                  ),
                ],
              ),

              // Operational Notes if provided
              if (trip.operationalNotes != null && trip.operationalNotes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: DriverColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          trip.operationalNotes!,
                          style: const TextStyle(fontSize: 11, color: DriverColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Route & Schedule details
              Row(
                children: [
                  // From
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.departureTime,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: DriverColors.textPrimary,
                          ),
                        ),
                        Text(
                          trip.fromCity,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: DriverColors.textPrimary,
                          ),
                        ),
                        Text(
                          trip.fromTerminal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: DriverColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Route indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: DriverColors.textMuted,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.distance.isNotEmpty ? trip.distance : trip.duration,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: DriverColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // To
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          trip.arrivalTime,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: DriverColors.textPrimary,
                          ),
                        ),
                        Text(
                          trip.toCity,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: DriverColors.textPrimary,
                          ),
                        ),
                        Text(
                          trip.toTerminal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 11,
                            color: DriverColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Crew & Operator details
              if (trip.driverName != null || trip.conductorName != null || trip.operatorName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DriverColors.border),
                  ),
                  child: Row(
                    children: [
                      if (trip.driverName != null) ...[
                        const Icon(Icons.drive_eta_rounded, size: 14, color: DriverColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trip.driverName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DriverColors.textPrimary),
                          ),
                        ),
                      ],
                      if (trip.conductorName != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.badge_rounded, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trip.conductorName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DriverColors.textPrimary),
                          ),
                        ),
                      ],
                      if (trip.operatorName != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.business_rounded, size: 14, color: DriverColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          trip.operatorName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: DriverColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Footer: Journey date, passenger count, and Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: DriverColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trip.journeyDate,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: DriverColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.airline_seat_recline_extra_rounded,
                        size: 14,
                        color: DriverColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.bookedSeats}/${trip.totalSeats} booked (${trip.availableSeats} open)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: DriverColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        quickActionLabel ?? 'Trip Details',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: DriverColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
