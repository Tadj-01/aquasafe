import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/branding/app_branding.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/report_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/report.dart';
import '../../models/repair_team.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/priority_badge.dart';
import '../leak_map/leak_map_screen.dart';
import 'route_map_screen.dart';
import 'widgets/status_change_dialog.dart';
import 'widgets/priority_change_dialog.dart';
import 'widgets/assign_team_dialog.dart';
import 'widgets/status_history_timeline.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailsScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  Report? _report;
  List<RepairTeam> _teams = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report = await ReportApiService.getReportDetails(widget.reportId);
      final teams = await ReportApiService.getRepairTeams();
      if (mounted) {
        setState(() {
          _report = report;
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _changeStatus(String newStatus, String? note) async {
    try {
      final updated = await ReportApiService.updateStatus(
        widget.reportId,
        newStatus,
        note,
      );
      if (mounted) {
        setState(() {
          _report = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${StatusBadge.getStatusLabel(newStatus)}'),
            backgroundColor: AppBranding.statusResolved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppBranding.statusUnderRepair,
          ),
        );
      }
    }
  }

  Future<void> _changePriority(String newPriority, String? note) async {
    try {
      final updated = await ReportApiService.updatePriority(
        widget.reportId,
        newPriority,
        note,
      );
      if (mounted) {
        setState(() {
          _report = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Priority updated to $newPriority'),
            backgroundColor: AppBranding.statusResolved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update priority: $e'),
            backgroundColor: AppBranding.statusUnderRepair,
          ),
        );
      }
    }
  }

  Future<void> _assignTeam(String? teamId, String? note) async {
    try {
      final updated = await ReportApiService.assignTeam(
        widget.reportId,
        teamId,
        note,
      );
      if (mounted) {
        setState(() {
          _report = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team assignment updated.'),
            backgroundColor: AppBranding.statusResolved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign team: $e'),
            backgroundColor: AppBranding.statusUnderRepair,
          ),
        );
      }
    }
  }

  Future<void> _openExternalGoogleMaps() async {
    if (_report == null) return;
    final lat = _report!.latitude;
    final lng = _report!.longitude;
    final googleMapsUrl =
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Details')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage ?? 'Report not found.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final report = _report!;
    final reportCoords = LatLng(report.latitude, report.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text('Report #${AppFormatters.formatShortId(report.id)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _fetchDetails,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppBranding.pureWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Status'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => StatusChangeDialog(
                        currentStatus: report.status,
                        onConfirm: _changeStatus,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Priority'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => PriorityChangeDialog(
                        currentPriority: report.priority,
                        onConfirm: _changePriority,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.groups_outlined, size: 18),
                  label: const Text('Assign'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AssignTeamDialog(
                        teams: _teams,
                        currentlyAssignedTeamId: report.assignedTeamId,
                        onConfirm: _assignTeam,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Full photograph
            Image.network(
              ApiConstants.resolvePhotoUrl(report.photoUrl),
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppBranding.lightWaterBlue,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: AppBranding.secondaryText),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Priority Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(status: report.status, fontSize: 13),
                      PriorityBadge(priority: report.priority, fontSize: 13),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.place_rounded,
                                  color: AppBranding.primaryBlue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${report.wilayaName ?? "Wilaya Unspecified"} • ${report.communeName ?? "Commune Unspecified"}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppBranding.deepNavy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            'Administrative (ONS):',
                            'Wilaya: ${report.wilayaCode ?? "N/A"} | Commune: ${report.communeCode ?? "N/A"}',
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Exact GPS Coordinates:',
                            '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                            isMonospace: true,
                          ),
                          if (report.gpsAccuracy != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'GPS Accuracy:',
                              '±${report.gpsAccuracy!.toStringAsFixed(1)} meters',
                            ),
                          ],
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Submission Date:',
                            AppFormatters.formatDateTime(report.createdAt),
                          ),
                          if (report.assignedTeam != null) ...[
                            const Divider(height: 20),
                            _buildDetailRow(
                              'Assigned Repair Team:',
                              '${report.assignedTeam!.name} (${report.assignedTeam!.phone ?? "No phone"})',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Citizen note
                  if (report.note != null && report.note!.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Citizen Note / Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppBranding.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppBranding.lightBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppBranding.cardBorder),
                      ),
                      child: Text(
                        report.note!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppBranding.mainText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Map Preview Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Location Preview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppBranding.deepNavy,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.fullscreen, size: 18),
                        label: const Text('View on Map'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LeakMapScreen(
                                initialFocusLocation: reportCoords,
                                focusReportId: report.id,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Mini Map Box (flutter_map)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: reportCoords,
                              initialZoom: 15.0,
                              minZoom: 4.0,
                              maxZoom: 18.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'dz.aquasafe.frontend',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: reportCoords,
                                    width: 36,
                                    height: 36,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppBranding.statusUnderRepair,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.water_drop_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LeakMapScreen(
                                        initialFocusLocation: reportCoords,
                                        focusReportId: report.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Route path button if assigned team has coordinates
                  if (report.assignedTeam != null &&
                      report.assignedTeam!.latitude != null &&
                      report.assignedTeam!.longitude != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.alt_route_rounded, size: 18),
                        label: Text('View Route from ${report.assignedTeam!.name}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppBranding.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteMapScreen(
                                teamLat: report.assignedTeam!.latitude!,
                                teamLng: report.assignedTeam!.longitude!,
                                leakLat: report.latitude,
                                leakLng: report.longitude,
                                teamName: report.assignedTeam!.name,
                                reportId: report.id,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // External Google Maps Navigation Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('Open in Google Maps for Navigation'),
                      onPressed: _openExternalGoogleMaps,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Status History Audit Log
                  const Text(
                    'Status & Audit History',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppBranding.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatusHistoryTimeline(history: report.statusHistory),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMonospace = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppBranding.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontFamily: isMonospace ? 'monospace' : null,
              fontWeight: FontWeight.w600,
              color: AppBranding.deepNavy,
            ),
          ),
        ),
      ],
    );
  }
}
