import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/branding/app_branding.dart';
import '../../core/services/geo_service.dart';
import '../../core/services/report_service.dart';
import '../../models/geo_models.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<ReportMapItem> _allReports = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL';

  // Search state
  bool _isSearching = false;
  List<GeoSearchResult> _geoSearchResults = [];
  List<ReportMapItem> _matchingReports = [];
  Timer? _debounceTimer;

  final List<String> _filters = [
    'ALL',
    'NEW',
    'VERIFIED',
    'ASSIGNED',
    'UNDER_REPAIR',
    'RESOLVED',
  ];

  // True geographical center of Algeria (Lat 28.0339, Lon 1.6596)
  static const LatLng _algeriaCenter = LatLng(28.0339, 1.6596);
  static const double _algeriaOverviewZoom = 5.2;

  // Approximate coordinates for Algerian Wilayas (for instant local response)
  static const Map<String, LatLng> _wilayaCoords = {
    '01': LatLng(27.8742, -0.2939), // Adrar
    '02': LatLng(36.1652, 1.3345),  // Chlef
    '03': LatLng(33.8000, 2.8651),  // Laghouat
    '04': LatLng(35.8755, 7.1135),  // Oum El Bouaghi
    '05': LatLng(35.5559, 6.1741),  // Batna
    '06': LatLng(36.7558, 5.0843),  // Béjaïa
    '07': LatLng(34.8504, 5.7280),  // Biskra
    '08': LatLng(31.6167, -2.2167), // Béchar
    '09': LatLng(36.4700, 2.8300),  // Blida
    '10': LatLng(36.3749, 3.9020),  // Bouira
    '11': LatLng(22.7850, 5.5228),  // Tamanrasset
    '12': LatLng(35.4042, 8.1242),  // Tébessa
    '13': LatLng(34.8783, -1.3150), // Tlemcen
    '14': LatLng(35.3710, 1.3170),  // Tiaret
    '15': LatLng(36.7118, 4.0459),  // Tizi Ouzou
    '16': LatLng(36.7538, 3.0588),  // Alger
    '17': LatLng(34.6728, 3.2630),  // Djelfa
    '18': LatLng(36.8205, 5.7667),  // Jijel
    '19': LatLng(36.1911, 5.4137),  // Sétif
    '20': LatLng(34.8303, 0.1517),  // Saïda
    '21': LatLng(36.8762, 6.9092),  // Skikda
    '22': LatLng(35.1899, -0.6308), // Sidi Bel Abbès
    '23': LatLng(36.9000, 7.7667),  // Annaba
    '24': LatLng(36.4621, 7.4261),  // Guelma
    '25': LatLng(36.3650, 6.6147),  // Constantine
    '26': LatLng(36.2642, 2.7539),  // Médéa
    '27': LatLng(35.9312, 0.0892),  // Mostaganem
    '28': LatLng(35.7058, 4.5419),  // M'Sila
    '29': LatLng(35.3946, 0.1403),  // Mascara
    '30': LatLng(31.9493, 5.3250),  // Ouargla
    '31': LatLng(35.6976, -0.6337), // Oran
    '32': LatLng(32.6833, 1.0167),  // El Bayadh
    '33': LatLng(28.4467, 9.8700),  // Illizi
    '34': LatLng(36.0732, 4.7611),  // Bordj Bou Arréridj
    '35': LatLng(36.7599, 3.4772),  // Boumerdes
    '36': LatLng(36.7672, 8.3138),  // El Tarf
    '37': LatLng(27.6711, -8.1474), // Tindouf
    '38': LatLng(35.6072, 1.8108),  // Tissemsilt
    '39': LatLng(33.3683, 6.8675),  // El Oued
    '40': LatLng(35.4358, 7.1433),  // Khenchela
    '41': LatLng(36.2864, 7.9511),  // Souk Ahras
    '42': LatLng(36.5925, 2.4475),  // Tipaza
    '43': LatLng(36.4503, 6.2644),  // Mila
    '44': LatLng(36.2644, 1.9686),  // Aïn Defla
    '45': LatLng(32.7500, -0.3167), // Naama
    '46': LatLng(35.2975, -1.1403), // Aïn Temouchent
    '47': LatLng(32.4909, 3.6736),  // Ghardaïa
    '48': LatLng(35.7372, 0.5558),  // Relizane
    '49': LatLng(29.2639, 0.2310),  // Timimoun
    '50': LatLng(21.3283, 0.9231),  // Bordj Badji Mokhtar
    '51': LatLng(34.3333, 5.0667),  // Ouled Djellal
    '52': LatLng(30.1333, -2.1667), // Béni Abbès
    '53': LatLng(27.2106, 2.4608),  // In Salah
    '54': LatLng(19.5667, 5.7667),  // In Guezzam
    '55': LatLng(33.1072, 6.0636),  // Touggourt
    '56': LatLng(24.5533, 9.4842),  // Djanet
    '57': LatLng(33.9500, 5.9167),  // El M'Ghaier
    '58': LatLng(30.5833, 2.8833),  // El Meniaa
  };

  @override
  void initState() {
    super.initState();
    _loadMapMarkers();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim().toLowerCase();

    if (trimmed.isEmpty) {
      setState(() {
        _geoSearchResults = [];
        _matchingReports = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // 1. Filter local reports
      final reportMatches = _allReports.where((r) {
        final matchesWilaya = r.wilayaName?.toLowerCase().contains(trimmed) ?? false;
        final matchesCommune = r.communeName?.toLowerCase().contains(trimmed) ?? false;
        final matchesNote = r.note?.toLowerCase().contains(trimmed) ?? false;
        final matchesId = r.id.toLowerCase().contains(trimmed);
        return matchesWilaya || matchesCommune || matchesNote || matchesId;
      }).take(5).toList();

      // 2. Query geo communes / wilayas
      List<GeoSearchResult> geoResults = [];
      try {
        geoResults = await GeoApiService.searchLocations(trimmed);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _matchingReports = reportMatches;
          _geoSearchResults = geoResults;
          _isSearching = false;
        });
      }
    });
  }

  void _navigateToLocation(double lat, double lng, {double zoom = 13.0}) {
    _searchFocusNode.unfocus();
    setState(() {
      _geoSearchResults = [];
      _matchingReports = [];
    });
    _mapController.move(LatLng(lat, lng), zoom);
  }

  void _resetToAlgeriaView() {
    _searchFocusNode.unfocus();
    _mapController.move(_algeriaCenter, _algeriaOverviewZoom);
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
    final initialZoom = widget.initialFocusLocation != null ? 15.0 : _algeriaOverviewZoom;

    final hasSearchResults =
        _geoSearchResults.isNotEmpty || _matchingReports.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Leak Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.public_rounded),
            tooltip: 'View Whole Algeria',
            onPressed: _resetToAlgeriaView,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Map',
            onPressed: _loadMapMarkers,
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Tile Layer with Algeria Boundaries
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: startLocation,
              initialZoom: initialZoom,
              minZoom: 3.5, // Allows zooming out to view all of Algeria comfortably
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

          // Search Bar & Filter Section
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Input Box
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search city, wilaya, or report ID...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppBranding.primaryBlue),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : (_isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : null),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Horizontal Filters
                SizedBox(
                  height: 38,
                  child: ListView.separated(
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
                            fontSize: 11,
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
              ],
            ),
          ),

          // Search Results Dropdown Overlay
          if (hasSearchResults)
            Positioned(
              top: 68,
              left: 12,
              right: 12,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    children: [
                      if (_matchingReports.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 6, 16, 4),
                          child: Text(
                            'LEAK REPORTS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppBranding.secondaryText,
                            ),
                          ),
                        ),
                        ..._matchingReports.map((report) => ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.water_drop_rounded,
                                color: _getStatusColor(report.status),
                                size: 20,
                              ),
                              title: Text(
                                'Report #${report.id.substring(0, 8)}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${report.communeName ?? report.wilayaName ?? "Algeria"} • ${report.status}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () {
                                _navigateToLocation(
                                    report.latitude, report.longitude,
                                    zoom: 16.0);
                                _onMarkerTapped(report);
                              },
                            )),
                      ],
                      if (_geoSearchResults.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 6, 16, 4),
                          child: Text(
                            'LOCATIONS (CITIES & WILAYAS)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppBranding.secondaryText,
                            ),
                          ),
                        ),
                        ..._geoSearchResults.map((loc) {
                          // Try getting coordinates from result or local wilaya dictionary
                          double? lat = loc.latitude;
                          double? lng = loc.longitude;
                          if (lat == null || lng == null) {
                            final wCoords = _wilayaCoords[loc.wilayaCode];
                            if (wCoords != null) {
                              lat = wCoords.latitude;
                              lng = wCoords.longitude;
                            }
                          }

                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_rounded,
                                color: AppBranding.primaryBlue, size: 20),
                            title: Text(
                              '${loc.communeNameFr} (${loc.communeNameAr})',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Wilaya: ${loc.wilayaCode} - ${loc.wilayaNameFr}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              if (lat != null && lng != null) {
                                _navigateToLocation(lat, lng, zoom: 13.5);
                              }
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Loading overlay
          if (_isLoading)
            Positioned(
              top: 115,
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
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
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

          // Zoom In / Zoom Out & Whole Algeria View Controls
          Positioned(
            bottom: 20,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'fit_algeria_fab',
                  backgroundColor: AppBranding.pureWhite,
                  foregroundColor: AppBranding.primaryBlue,
                  elevation: 3,
                  tooltip: 'Whole Algeria',
                  onPressed: _resetToAlgeriaView,
                  child: const Icon(Icons.public_rounded, size: 20),
                ),
                const SizedBox(height: 8),
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
                      (currentZoom + 1).clamp(3.5, 18.0),
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
                      (currentZoom - 1).clamp(3.5, 18.0),
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
