import 'package:flutter/foundation.dart';

class ApiConstants {
  // ──────────────────────────────────────────────────────────
  // Change this to your computer's LAN IP so your phone can
  // reach the backend. Run `hostname -I` on Linux to find it.
  // ──────────────────────────────────────────────────────────
  /*static const String _lanIp = '192.168.100.6';

  /// Resolves the correct backend URL depending on where the app runs.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    return 'http://$_lanIp:8000';
  }*/
  static String get baseUrl {
    return 'https://aquasafe-api.onrender.com';
  }

  /// Google OAuth Web Client ID for Android ID Token verification (optional, if using Google Auth)
  static const String googleServerClientId = '';

  static String get apiPrefix => '$baseUrl/api';

  // Auth endpoints
  static String get login => '$apiPrefix/auth/login';
  static String get signup => '$apiPrefix/auth/signup';
  static String get googleLogin => '$apiPrefix/auth/google';
  static String get me => '$apiPrefix/auth/me';
  static String get updateProfile => '$apiPrefix/auth/profile';
  static String get refresh => '$apiPrefix/auth/refresh';

  // Administrator supervisor management
  static String get administrators => '$apiPrefix/administrators';
  static String get adminPendingCount => '$apiPrefix/administrators/pending-count';
  static String administratorDetails(String id) => '$apiPrefix/administrators/$id';
  static String administratorDecision(String id) =>
      '$apiPrefix/administrators/$id/decision';

  // Report endpoints
  static String get reports => '$apiPrefix/reports';
  static String get reportsMap => '$apiPrefix/reports/map';
  static String reportDetails(String id) => '$apiPrefix/reports/$id';
  static String reportPublicStatus(String id) =>
      '$apiPrefix/reports/$id/public-status';
  static String reportHistory(String id) => '$apiPrefix/reports/$id/history';
  static String reportStatus(String id) => '$apiPrefix/reports/$id/status';
  static String reportPriority(String id) => '$apiPrefix/reports/$id/priority';
  static String reportAssignment(String id) =>
      '$apiPrefix/reports/$id/assignment';

  // Dashboard endpoints
  static String get dashboardStats => '$apiPrefix/dashboard/statistics';

  // Repair teams
  static String get repairTeams => '$apiPrefix/repair-teams';
  static String repairTeamDetails(String id) => '$apiPrefix/repair-teams/$id';

  // Routing
  static String get routingRoute => '$apiPrefix/routing/route';

  // Geographic data (Syscli Algeria)
  static String get geoWilayas => '$apiPrefix/geo/wilayas';
  static String geoCommunes(String wilayaCode) =>
      '$apiPrefix/geo/wilayas/$wilayaCode/communes';
  static String get geoSearch => '$apiPrefix/geo/search';
  static String get geoLookup => '$apiPrefix/geo/lookup';

  // Resolve photo URL (adds baseUrl if photo_url is relative)
  static String resolvePhotoUrl(String photoUrl) {
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl;
    }
    return '$baseUrl$photoUrl';
  }
}
