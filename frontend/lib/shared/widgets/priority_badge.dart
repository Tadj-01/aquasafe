import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final double fontSize;
  final EdgeInsets padding;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  static Color getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        return AppBranding.priorityCritical;
      case 'HIGH':
        return AppBranding.priorityHigh;
      case 'NORMAL':
      default:
        return AppBranding.priorityNormal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getPriorityColor(priority);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
