import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../../models/geo_models.dart';

class GeoApiService {
  static Future<List<Wilaya>> getWilayas() async {
    final response = await ApiClient.get(ApiConstants.geoWilayas);
    if (response is List) {
      return response
          .map((item) => Wilaya.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<List<Commune>> getCommunesForWilaya(String wilayaCode) async {
    final response =
        await ApiClient.get(ApiConstants.geoCommunes(wilayaCode));
    if (response is List) {
      return response
          .map((item) => Commune.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<List<GeoSearchResult>> searchLocations(String query) async {
    final response = await ApiClient.get(
      ApiConstants.geoSearch,
      queryParams: {'q': query, 'limit': 10},
    );
    if (response is List) {
      return response
          .map((item) => GeoSearchResult.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> lookupCoordinates(
      double lat, double lng) async {
    final response = await ApiClient.get(
      ApiConstants.geoLookup,
      queryParams: {'lat': lat, 'lng': lng},
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return null;
  }
}
