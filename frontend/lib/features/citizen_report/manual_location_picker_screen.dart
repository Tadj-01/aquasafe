import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/branding/app_branding.dart';

class ManualLocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const ManualLocationPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<ManualLocationPickerScreen> createState() =>
      _ManualLocationPickerScreenState();
}

class _ManualLocationPickerScreenState
    extends State<ManualLocationPickerScreen> {
  late LatLng _selectedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(widget.initialLat, widget.initialLng);
  }

  void _onConfirm() {
    Navigator.pop(context, {
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Location'),
        actions: [
          TextButton(
            onPressed: _onConfirm,
            child: const Text(
              'CONFIRM',
              style: TextStyle(
                color: AppBranding.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 16.0,
              minZoom: 4.0,
              maxZoom: 18.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _selectedLocation = camera.center;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dz.aquasafe.frontend',
              ),
            ],
          ),

          // Center crosshair marker
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppBranding.deepNavy.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Move map to position leak',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppBranding.statusUnderRepair,
                    size: 42,
                  ),
                ],
              ),
            ),
          ),

          // Coordinate readout bar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppBranding.pureWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selected Coordinates:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppBranding.deepNavy,
                        ),
                      ),
                      Text(
                        '${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppBranding.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      child: const Text('Confirm This Location'),
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
