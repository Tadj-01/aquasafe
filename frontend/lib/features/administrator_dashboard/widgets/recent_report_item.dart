import 'package:flutter/material.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/report.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/priority_badge.dart';

class RecentReportItem extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const RecentReportItem({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ApiConstants.resolvePhotoUrl(report.photoUrl),
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 54,
                      height: 54,
                      color: AppBranding.lightWaterBlue,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppBranding.secondaryText,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${AppFormatters.formatShortId(report.id)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: AppBranding.deepNavy,
                          ),
                        ),
                        Text(
                          AppFormatters.formatDate(report.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppBranding.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.wilayaName ?? "Algeria"} • ${report.communeName ?? "Unassigned"}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppBranding.deepNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusBadge(status: report.status, fontSize: 10),
                        const SizedBox(width: 6),
                        PriorityBadge(priority: report.priority, fontSize: 10),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppBranding.secondaryText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
