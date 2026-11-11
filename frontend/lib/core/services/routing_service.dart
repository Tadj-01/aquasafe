import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RoutingService {
  static Future<RouteResult?> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      // First try our backend proxy
      final uri = Uri.parse(
        '${ApiConstants.routingRoute}?from_lat=$fromLat&from_lng=$fromLng&to_lat=$toLat&to_lng=$toLng',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final rawPoints = data['points'] as List;
        final points = rawPoints
            .map<LatLng>((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
            .toList();
        return RouteResult(
          points: points,
          distanceKm: (data['distance_km'] as num).toDouble(),
          durationMinutes: (data['duration_minutes'] as num).toDouble(),
        );
      }
    } catch (_) {
      // Fallback directly to public OSRM
      try {
        final osrmUrl =
            'http://router.project-osrm.org/route/v1/driving/$fromLng,$fromLat;$toLng,$toLat?overview=full&geometries=geojson';
        final response = await http.get(Uri.parse(osrmUrl)).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          final points = coords
              .map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          return RouteResult(
            points: points,
            distanceKm: (route['distance'] as num).toDouble() / 1000.0,
            durationMinutes: (route['duration'] as num).toDouble() / 60.0,
          );
        }
      } catch (_) {}
    }
    return null;
  }
}
