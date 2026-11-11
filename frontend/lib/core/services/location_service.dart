import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final bool isManual;
  final String? error;

  LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.isManual = false,
    this.error,
  });
}

class LocationService {
  // Default fallback center for Algeria (Algiers center) if GPS is denied or unavailable
  static const double defaultAlgeriaLat = 36.7538;
  static const double defaultAlgeriaLon = 3.0588;

  static Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          latitude: defaultAlgeriaLat,
          longitude: defaultAlgeriaLon,
          isManual: true,
          error: 'Location services are disabled on device.',
        );
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            latitude: defaultAlgeriaLat,
            longitude: defaultAlgeriaLon,
            isManual: true,
            error: 'Location permissions are denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          latitude: defaultAlgeriaLat,
          longitude: defaultAlgeriaLon,
          isManual: true,
          error:
              'Location permissions are permanently denied. Please select location manually.',
        );
      }

      // Permissions granted, get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        isManual: false,
      );
    } catch (e) {
      return LocationResult(
        latitude: defaultAlgeriaLat,
        longitude: defaultAlgeriaLon,
        isManual: true,
        error: 'Could not obtain GPS location: ${e.toString()}',
      );
    }
  }
}
