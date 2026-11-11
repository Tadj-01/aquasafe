import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/utils/formatters.dart';
import '../../models/report.dart';

class ReportConfirmationScreen extends StatelessWidget {
  final ReportConfirmation confirmation;

  const ReportConfirmationScreen({
    super.key,
    required this.confirmation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Report Confirmation'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFDEF7EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppBranding.statusResolved,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Report Successfully Submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppBranding.deepNavy,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thank you for reporting this water leak. Your report has been dispatched to the local water distribution authority.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppBranding.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                elevation: 0,
                color: AppBranding.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppBranding.cardBorder,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Report ID',
                        confirmation.id,
                        isCode: true,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Submission Date',
                        AppFormatters.formatDateTime(confirmation.createdAt),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Initial Status',
                        confirmation.status,
                        statusColor: AppBranding.statusNew,
                      ),
                      if (confirmation.wilayaName != null) ...[
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Wilaya (Syscli)',
                          '${confirmation.wilayaCode ?? ""} - ${confirmation.wilayaName}',
                        ),
                      ],
                      if (confirmation.communeName != null) ...[
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Commune (Syscli)',
                          confirmation.communeName!,
                        ),
                      ],
                      const Divider(height: 24),
                      _buildInfoRow(
                        'GPS Coordinates',
                        AppFormatters.formatCoordinates(
                          confirmation.latitude,
                          confirmation.longitude,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home_rounded, size: 20),
                  label: const Text('Back to Home'),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isCode = false,
    Color? statusColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppBranding.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isCode ? 12 : 13,
              fontFamily: isCode ? 'monospace' : null,
              fontWeight: isCode ? FontWeight.bold : FontWeight.w600,
              color: statusColor ?? AppBranding.deepNavy,
            ),
          ),
        ),
      ],
    );
  }
}
