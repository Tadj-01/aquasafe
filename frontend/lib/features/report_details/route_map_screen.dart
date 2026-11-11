import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/branding/app_branding.dart';
import '../../core/services/routing_service.dart';

class RouteMapScreen extends StatefulWidget {
  final double teamLat;
  final double teamLng;
  final double leakLat;
  final double leakLng;
  final String teamName;
  final String reportId;

  const RouteMapScreen({
    super.key,
    required this.teamLat,
    required this.teamLng,
    required this.leakLat,
    required this.leakLng,
    required this.teamName,
    required this.reportId,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final MapController _mapController = MapController();
  RouteResult? _routeResult;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await RoutingService.getRoute(
      fromLat: widget.teamLat,
      fromLng: widget.teamLng,
      toLat: widget.leakLat,
      toLng: widget.leakLng,
    );

    if (mounted) {
      setState(() {
        _routeResult = res;
        _isLoading = false;
        if (res == null) {
          _error = 'Could not calculate driving route between team and leak.';
        }
      });

      if (res != null && res.points.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final bounds = LatLngBounds.fromPoints([
            LatLng(widget.teamLat, widget.teamLng),
            LatLng(widget.leakLat, widget.leakLng),
            ...res.points,
          ]);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50),
            ),
          );
        });
      }
    }
  }

  Future<void> _launchTurnByTurn() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${widget.teamLat},${widget.teamLng}&destination=${widget.leakLat},${widget.leakLng}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamPoint = LatLng(widget.teamLat, widget.teamLng);
    final leakPoint = LatLng(widget.leakLat, widget.leakLng);
    final centerPoint = LatLng(
      (widget.teamLat + widget.leakLat) / 2,
      (widget.teamLng + widget.leakLng) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch Route'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRoute,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPoint,
              initialZoom: 13.0,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dz.aquasafe.frontend',
              ),
              if (_routeResult != null && _routeResult!.points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeResult!.points,
                      strokeWidth: 5.0,
                      color: AppBranding.primaryBlue,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Team base marker
                  Marker(
                    point: teamPoint,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppBranding.statusAssigned,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.engineering_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  // Leak location marker
                  Marker(
                    point: leakPoint,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppBranding.statusUnderRepair,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_isLoading)
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
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
                      Text('Calculating optimal driving route...'),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Route Info Sheet
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alt_route_rounded,
                          color: AppBranding.primaryBlue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team: ${widget.teamName}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppBranding.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Target Leak: #${widget.reportId.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppBranding.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Distance',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppBranding.secondaryText)),
                          const SizedBox(height: 2),
                          Text(
                            _routeResult != null
                                ? '${_routeResult!.distanceKm.toStringAsFixed(1)} km'
                                : '--',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppBranding.deepNavy),
                          ),
                        ],
                      ),
                      Container(height: 28, width: 1, color: AppBranding.cardBorder),
                      Column(
                        children: [
                          const Text('Est. Drive Time',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppBranding.secondaryText)),
                          const SizedBox(height: 2),
                          Text(
                            _routeResult != null
                                ? '${_routeResult!.durationMinutes.toStringAsFixed(0)} min'
                                : '--',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppBranding.primaryBlue),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('Start Turn-by-Turn GPS Navigation'),
                      onPressed: _launchTurnByTurn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
