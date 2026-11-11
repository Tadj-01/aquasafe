import 'package:flutter/material.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/report.dart';
import '../../../shared/widgets/status_badge.dart';

class StatusHistoryTimeline extends StatelessWidget {
  final List<StatusHistoryItem> history;

  const StatusHistoryTimeline({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No history recorded yet.',
          style: TextStyle(
            fontSize: 13,
            color: AppBranding.secondaryText,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final isFirst = index == 0;
        final isLast = index == history.length - 1;
        final color = StatusBadge.getStatusColor(item.newStatus);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line and dot
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppBranding.cardBorder,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(status: item.newStatus, fontSize: 10),
                          Text(
                            AppFormatters.formatDateTime(item.changedAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppBranding.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.note!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppBranding.deepNavy,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
