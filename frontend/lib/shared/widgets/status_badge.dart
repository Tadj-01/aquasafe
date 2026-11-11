import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return AppBranding.statusNew; // Blue
      case 'VERIFIED':
        return AppBranding.statusVerified; // Orange
      case 'ASSIGNED':
        return AppBranding.statusAssigned; // Purple
      case 'UNDER_REPAIR':
        return AppBranding.statusUnderRepair; // Red
      case 'RESOLVED':
        return AppBranding.statusResolved; // Green
      default:
        return AppBranding.secondaryText;
    }
  }

  static String getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return 'NEW';
      case 'VERIFIED':
        return 'VERIFIED';
      case 'ASSIGNED':
        return 'ASSIGNED';
      case 'UNDER_REPAIR':
        return 'UNDER REPAIR';
      case 'RESOLVED':
        return 'RESOLVED';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(status);
    final label = getStatusLabel(status);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
