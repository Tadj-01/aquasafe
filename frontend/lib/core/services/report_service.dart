import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../../models/report.dart';
import '../../models/dashboard_stats.dart';
import '../../models/repair_team.dart';

class ReportApiService {
  // Citizen submit report
  static Future<ReportConfirmation> submitReport({
    required double latitude,
    required double longitude,
    double? gpsAccuracy,
    String? note,
    required List<int> photoBytes,
    required String photoFilename,
  }) async {
    final fields = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    if (gpsAccuracy != null) {
      fields['gps_accuracy'] = gpsAccuracy.toString();
    }
    if (note != null && note.trim().isNotEmpty) {
      fields['note'] = note.trim();
    }

    final response = await ApiClient.postMultipart(
      url: ApiConstants.reports,
      fields: fields,
      fileField: 'photo',
      fileBytes: photoBytes,
      filename: photoFilename,
    );

    return ReportConfirmation.fromJson(response as Map<String, dynamic>);
  }

  // Citizen public status check
  static Future<Map<String, dynamic>> getPublicStatus(String reportId) async {
    final response =
        await ApiClient.get(ApiConstants.reportPublicStatus(reportId));
    return response as Map<String, dynamic>;
  }

  // Administrator list reports with filters
  static Future<List<Report>> listReports({
    int skip = 0,
    int limit = 50,
    String? status,
    String? priority,
    String? wilayaCode,
    String? communeCode,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty && status != 'ALL') {
      params['status'] = status;
    }
    if (priority != null && priority.isNotEmpty && priority != 'ALL') {
      params['priority'] = priority;
    }
    if (wilayaCode != null && wilayaCode.isNotEmpty && wilayaCode != 'ALL') {
      params['wilaya_code'] = wilayaCode;
    }
    if (communeCode != null && communeCode.isNotEmpty && communeCode != 'ALL') {
      params['commune_code'] = communeCode;
    }
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (startDate != null) {
      params['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      params['end_date'] = endDate.toIso8601String();
    }

    final response =
        await ApiClient.get(ApiConstants.reports, queryParams: params);
    if (response is List) {
      return response
          .map((item) => Report.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // Administrator map markers
  static Future<List<ReportMapItem>> getMapReports({
    String? status,
    String? wilayaCode,
  }) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status != 'ALL') {
      params['status'] = status;
    }
    if (wilayaCode != null && wilayaCode.isNotEmpty && wilayaCode != 'ALL') {
      params['wilaya_code'] = wilayaCode;
    }

    final response =
        await ApiClient.get(ApiConstants.reportsMap, queryParams: params);
    if (response is List) {
      return response
          .map((item) => ReportMapItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // Administrator get report details
  static Future<Report> getReportDetails(String reportId) async {
    final response =
        await ApiClient.get(ApiConstants.reportDetails(reportId));
    return Report.fromJson(response as Map<String, dynamic>);
  }

  // Administrator update report status
  static Future<Report> updateStatus(
      String reportId, String newStatus, String? note) async {
    final response = await ApiClient.patch(
      ApiConstants.reportStatus(reportId),
      body: {'status': newStatus, 'note': note},
    );
    return Report.fromJson(response as Map<String, dynamic>);
  }

  // Administrator update report priority
  static Future<Report> updatePriority(
      String reportId, String newPriority, String? note) async {
    final response = await ApiClient.patch(
      ApiConstants.reportPriority(reportId),
      body: {'priority': newPriority, 'note': note},
    );
    return Report.fromJson(response as Map<String, dynamic>);
  }

  // Administrator assign repair team
  static Future<Report> assignTeam(
      String reportId, String? teamId, String? note) async {
    final response = await ApiClient.patch(
      ApiConstants.reportAssignment(reportId),
      body: {'assigned_team_id': teamId, 'note': note},
    );
    return Report.fromJson(response as Map<String, dynamic>);
  }

  // Administrator dashboard statistics
  static Future<DashboardStats> getDashboardStats() async {
    final response = await ApiClient.get(ApiConstants.dashboardStats);
    return DashboardStats.fromJson(response as Map<String, dynamic>);
  }

  // Repair teams list
  static Future<List<RepairTeam>> getRepairTeams({bool activeOnly = false}) async {
    final response = await ApiClient.get(
      ApiConstants.repairTeams,
      queryParams: activeOnly ? {'active_only': true} : null,
    );
    if (response is List) {
      return response
          .map((item) => RepairTeam.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // Single repair team
  static Future<RepairTeam> getRepairTeam(String teamId) async {
    final response = await ApiClient.get(ApiConstants.repairTeamDetails(teamId));
    return RepairTeam.fromJson(response as Map<String, dynamic>);
  }

  // Create repair team
  static Future<RepairTeam> createRepairTeam(Map<String, dynamic> data) async {
    final response = await ApiClient.post(ApiConstants.repairTeams, body: data);
    return RepairTeam.fromJson(response as Map<String, dynamic>);
  }

  // Update repair team
  static Future<RepairTeam> updateRepairTeam(
      String teamId, Map<String, dynamic> data) async {
    final response =
        await ApiClient.patch(ApiConstants.repairTeamDetails(teamId), body: data);
    return RepairTeam.fromJson(response as Map<String, dynamic>);
  }

  // Delete repair team
  static Future<void> deleteRepairTeam(String teamId) async {
    await ApiClient.delete(ApiConstants.repairTeamDetails(teamId));
  }
}
