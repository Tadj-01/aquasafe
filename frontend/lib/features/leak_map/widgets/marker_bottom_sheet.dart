import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/report.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../report_details/report_details_screen.dart';

class MarkerBottomSheet extends StatelessWidget {
  final ReportMapItem item;

  const MarkerBottomSheet({
    super.key,
    required this.item,
  });

  static Future<void> openExternalGoogleMaps(double lat, double lng) async {
    final googleMapsUrl =
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Fallback open web URL
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: AppBranding.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppBranding.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  ApiConstants.resolvePhotoUrl(item.photoUrl),
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 76,
                    height: 76,
                    color: AppBranding.lightWaterBlue,
                    child: const Icon(Icons.broken_image,
                        color: AppBranding.secondaryText),
                  ),
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
                          '#${AppFormatters.formatShortId(item.id)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: AppBranding.deepNavy,
                          ),
                        ),
                        Text(
                          AppFormatters.formatDateTime(item.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppBranding.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.wilayaName ?? "Algeria"} • ${item.communeName ?? ""}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppBranding.deepNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusBadge(status: item.status, fontSize: 10),
                        const SizedBox(width: 6),
                        PriorityBadge(priority: item.priority, fontSize: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (item.note != null && item.note!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppBranding.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.note!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppBranding.mainText,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Actions
          Row(
            children: [
              // Open in Google Maps
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text('Navigate'),
                  onPressed: () {
                    openExternalGoogleMaps(item.latitude, item.longitude);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // View Details
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('View Details'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailsScreen(reportId: item.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
