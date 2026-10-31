import 'package:flutter/material.dart';

/// Reusable status pill badge with icon and customized color scheme
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isFilled;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isFilled = false,
    this.fontSize = 11.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFilled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFilled ? color : color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: fontSize + 1,
              color: isFilled ? Colors.white : color,
            ),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: isFilled ? Colors.white : color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
