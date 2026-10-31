import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/status_badge.dart';

/// Card displaying the assigned fleet bus details and technical status
class AssignedBusCard extends StatelessWidget {
  final String busNumber;
  final String busType;
  final String depotName;
  final VoidCallback? onInspectBus;

  const AssignedBusCard({
    super.key,
    required this.busNumber,
    required this.busType,
    required this.depotName,
    this.onInspectBus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: DriverColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DriverColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: DriverColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            busNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: DriverColors.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const StatusBadge(
                            label: 'ASSIGNED',
                            color: DriverColors.success,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        busType,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DriverColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_city_rounded,
                            size: 14,
                            color: DriverColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            depotName,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: DriverColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: DriverColors.surfaceSecondary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              border: Border(top: BorderSide(color: DriverColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    _FeatureChip(icon: Icons.ac_unit_rounded, label: 'AC Active'),
                    SizedBox(width: 8),
                    _FeatureChip(icon: Icons.gps_fixed_rounded, label: 'GPS Online'),
                    SizedBox(width: 8),
                    _FeatureChip(icon: Icons.wifi_rounded, label: 'Wi-Fi'),
                  ],
                ),
                if (onInspectBus != null)
                  InkWell(
                    onTap: onInspectBus,
                    child: const Text(
                      'View Layout →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: DriverColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: DriverColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: DriverColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
