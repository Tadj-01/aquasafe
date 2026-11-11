import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/branding/app_branding.dart';
import '../../core/services/location_service.dart';
import '../../core/services/report_service.dart';
import '../../core/services/geo_service.dart';
import 'manual_location_picker_screen.dart';
import 'report_confirmation_screen.dart';

class ReportLeakScreen extends StatefulWidget {
  const ReportLeakScreen({super.key});

  @override
  State<ReportLeakScreen> createState() => _ReportLeakScreenState();
}

class _ReportLeakScreenState extends State<ReportLeakScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _noteController = TextEditingController();

  // Photo state
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  String? _imageName;

  // Location state
  bool _isLoadingLocation = true;
  double? _latitude;
  double? _longitude;
  double? _accuracy;
  String? _locationStatus;
  String? _detectedWilaya;
  String? _detectedCommune;

  // Submission state
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Detecting GPS coordinates...';
    });

    final locResult = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _latitude = locResult.latitude;
        _longitude = locResult.longitude;
        _accuracy = locResult.accuracy;
        _isLoadingLocation = false;
        _locationStatus = locResult.error ?? 'GPS location acquired';
      });

      // Reverse lookup wilaya and commune with Syscli backend
      if (_latitude != null && _longitude != null) {
        _lookupAdministrativeLocation(_latitude!, _longitude!);
      }
    }
  }

  Future<void> _lookupAdministrativeLocation(
      double lat, double lng) async {
    try {
      final geo = await GeoApiService.lookupCoordinates(lat, lng);
      if (mounted && geo != null) {
        setState(() {
          _detectedWilaya = geo['wilaya_name'];
          _detectedCommune = geo['commune_name'];
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _imageBytes = bytes;
          _imageName = picked.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error capturing image: ${e.toString()}';
      });
    }
  }

  Future<void> _adjustLocationManually() async {
    final currentLat = _latitude ?? LocationService.defaultAlgeriaLat;
    final currentLng = _longitude ?? LocationService.defaultAlgeriaLon;

    final result = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(
        builder: (_) => ManualLocationPickerScreen(
          initialLat: currentLat,
          initialLng: currentLng,
        ),
      ),
    );

    if (result != null && mounted) {
      final selectedLat = result['latitude']!;
      final selectedLng = result['longitude']!;
      setState(() {
        _latitude = selectedLat;
        _longitude = selectedLng;
        _accuracy = null; // Manual selection has no GPS hardware accuracy
        _locationStatus = 'Location adjusted manually';
      });
      _lookupAdministrativeLocation(selectedLat, selectedLng);
    }
  }

  Future<void> _submitReport() async {
    if (_imageBytes == null) {
      setState(() {
        _errorMessage = 'Please take or choose a photograph of the water leak.';
      });
      return;
    }

    if (_latitude == null || _longitude == null) {
      setState(() {
        _errorMessage = 'GPS location is required. Please enable GPS or select location manually.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final confirmation = await ReportApiService.submitReport(
        latitude: _latitude!,
        longitude: _longitude!,
        gpsAccuracy: _accuracy,
        note: _noteController.text,
        photoBytes: _imageBytes!,
        photoFilename: _imageName ?? 'leak.jpg',
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReportConfirmationScreen(
              confirmation: confirmation,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Water Leak'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Photo Section
              _buildSectionTitle('1. Photograph of the Leak', isRequired: true),
              const SizedBox(height: 10),
              _buildPhotoCard(),
              const SizedBox(height: 24),

              // 2. GPS Location Section
              _buildSectionTitle('2. Location Coordinates', isRequired: true),
              const SizedBox(height: 10),
              _buildLocationCard(),
              const SizedBox(height: 24),

              // 3. Note Field
              _buildSectionTitle('3. Optional Description / Note', isRequired: false),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Heavy leak on the sidewalk, water overflowing near residential entrance...',
                ),
              ),
              const SizedBox(height: 24),

              // Error display
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppBranding.statusUnderRepair.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppBranding.statusUnderRepair.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppBranding.statusUnderRepair,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppBranding.statusUnderRepair,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 4. Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting Report...'),
                          ],
                        )
                      : const Text('Submit Report'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppBranding.deepNavy,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: AppBranding.statusUnderRepair,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoCard() {
    if (_imageBytes != null) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Image.memory(
              _imageBytes!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppBranding.statusResolved, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Photo attached',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppBranding.deepNavy,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retake'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppBranding.lightWaterBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                size: 36,
                color: AppBranding.primaryBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Add a clear photo of the leak',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppBranding.deepNavy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Taking a photo helps technicians evaluate the leak severity.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppBranding.secondaryText,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Camera'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: _latitude != null
                      ? AppBranding.primaryBlue
                      : AppBranding.secondaryText,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationStatus ?? 'Checking GPS...',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppBranding.deepNavy,
                    ),
                  ),
                ),
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppBranding.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Coordinates:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppBranding.secondaryText,
                          ),
                        ),
                        Text(
                          '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: AppBranding.deepNavy,
                          ),
                        ),
                      ],
                    ),
                    if (_accuracy != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Accuracy:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppBranding.secondaryText,
                            ),
                          ),
                          Text(
                            '±${_accuracy!.toStringAsFixed(1)} m',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppBranding.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_detectedWilaya != null || _detectedCommune != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Administrative:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppBranding.secondaryText,
                            ),
                          ),
                          Text(
                            '${_detectedWilaya ?? ""}${_detectedCommune != null ? " / $_detectedCommune" : ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppBranding.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh GPS'),
                    onPressed: _isLoadingLocation ? null : _fetchCurrentLocation,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text('Adjust on Map'),
                    onPressed: _adjustLocationManually,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
