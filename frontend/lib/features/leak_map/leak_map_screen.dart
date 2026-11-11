import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/branding/app_branding.dart';
import '../../core/services/report_service.dart';
import '../../models/report.dart';
import 'widgets/marker_bottom_sheet.dart';

class LeakMapScreen extends StatefulWidget {
  final LatLng? initialFocusLocation;
  final String? focusReportId;

  const LeakMapScreen({
    super.key,
    this.initialFocusLocation,
    this.focusReportId,
  });

  @override
  State<LeakMapScreen> createState() => _LeakMapScreenState();
}

class _LeakMapScreenState extends State<LeakMapScreen> {
  final MapController _mapController = MapController();
  List<ReportMapItem> _allReports = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL';

  final List<String> _filters = [
    'ALL',
    'NEW',
    'VERIFIED',
    'ASSIGNED',
    'UNDER_REPAIR',
    'RESOLVED',
  ];

  static const LatLng _algeriaCenter = LatLng(36.7538, 3.0588);

  @override
  void initState() {
    super.initState();
    _loadMapMarkers();
  }

  Future<void> _loadMapMarkers() async {
    setState(() => _isLoading = true);
    try {
      final reports = await ReportApiService.getMapReports(
        status: _selectedFilter == 'ALL' ? null : _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _allReports = reports;
          _isLoading = false;
        });

        if (widget.initialFocusLocation != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(widget.initialFocusLocation!, 15.0);
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return AppBranding.statusNew;
      case 'VERIFIED':
        return AppBranding.statusVerified;
      case 'ASSIGNED':
        return AppBranding.statusAssigned;
      case 'UNDER_REPAIR':
        return AppBranding.statusUnderRepair;
      case 'RESOLVED':
        return AppBranding.statusResolved;
      default:
        return AppBranding.primaryBlue;
    }
  }

  void _onMarkerTapped(ReportMapItem report) {
    _mapController.move(LatLng(report.latitude, report.longitude), 15.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkerBottomSheet(item: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startLocation = widget.initialFocusLocation ?? _algeriaCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Leak Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Map',
            onPressed: _loadMapMarkers,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: startLocation,
              initialZoom: widget.initialFocusLocation != null ? 15.0 : 10.0,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dz.aquasafe.frontend',
              ),
              MarkerLayer(
                markers: _allReports.map((r) {
                  final color = _getStatusColor(r.status);
                  return Marker(
                    point: LatLng(r.latitude, r.longitude),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _onMarkerTapped(r),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.water_drop_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top Filter Bar
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;

                  return ChoiceChip(
                    label: Text(
                      filter.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppBranding.pureWhite
                            : AppBranding.deepNavy,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppBranding.primaryBlue,
                    backgroundColor: AppBranding.pureWhite,
                    side: BorderSide(
                      color: isSelected
                          ? AppBranding.primaryBlue
                          : AppBranding.cardBorder,
                    ),
                    elevation: 1,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        _loadMapMarkers();
                      }
                    },
                  );
                },
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppBranding.pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Updating markers...',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Marker Legend
          Positioned(
            bottom: 20,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppBranding.pureWhite.withOpacity(0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppBranding.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(AppBranding.statusNew, 'New'),
                  const SizedBox(height: 3),
                  _buildLegendItem(AppBranding.statusVerified, 'Verified'),
                  const SizedBox(height: 3),
                  _buildLegendItem(AppBranding.statusAssigned, 'Assigned'),
                  const SizedBox(height: 3),
                  _buildLegendItem(AppBranding.statusUnderRepair, 'Under Repair'),
                  const SizedBox(height: 3),
                  _buildLegendItem(AppBranding.statusResolved, 'Resolved'),
                ],
              ),
            ),
          ),

          // Zoom In / Zoom Out Floating Controls
          Positioned(
            bottom: 20,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: AppBranding.pureWhite,
                  foregroundColor: AppBranding.deepNavy,
                  elevation: 2,
                  tooltip: 'Zoom In',
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (currentZoom + 1).clamp(4.0, 18.0),
                    );
                  },
                  child: const Icon(Icons.add, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: AppBranding.pureWhite,
                  foregroundColor: AppBranding.deepNavy,
                  elevation: 2,
                  tooltip: 'Zoom Out',
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (currentZoom - 1).clamp(4.0, 18.0),
                    );
                  },
                  child: const Icon(Icons.remove, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppBranding.deepNavy,
          ),
        ),
      ],
    );
  }
}
