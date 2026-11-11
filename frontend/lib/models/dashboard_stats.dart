import 'report.dart';

class WilayaCount {
  final String? wilayaCode;
  final String? wilayaName;
  final int count;

  WilayaCount({
    this.wilayaCode,
    this.wilayaName,
    required this.count,
  });

  factory WilayaCount.fromJson(Map<String, dynamic> json) {
    return WilayaCount(
      wilayaCode: json['wilaya_code'] as String?,
      wilayaName: json['wilaya_name'] as String?,
      count: json['count'] as int? ?? 0,
    );
  }
}

class DashboardStats {
  final int totalReports;
  final int newReports;
  final int verifiedReports;
  final int assignedReports;
  final int underRepairReports;
  final int resolvedReports;
  final Map<String, int> priorityCounts;
  final List<WilayaCount> topWilayas;
  final List<Report> recentReports;
  final List<ReportMapItem> mapPreview;

  DashboardStats({
    required this.totalReports,
    required this.newReports,
    required this.verifiedReports,
    required this.assignedReports,
    required this.underRepairReports,
    required this.resolvedReports,
    required this.priorityCounts,
    required this.topWilayas,
    required this.recentReports,
    required this.mapPreview,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final prioMap = <String, int>{};
    if (json['priority_counts'] != null) {
      (json['priority_counts'] as Map<String, dynamic>).forEach((k, v) {
        prioMap[k] = v as int;
      });
    }

    final wilayaList = <WilayaCount>[];
    if (json['top_wilayas'] != null) {
      for (var w in json['top_wilayas'] as List) {
        wilayaList.add(WilayaCount.fromJson(w as Map<String, dynamic>));
      }
    }

    final recentList = <Report>[];
    if (json['recent_reports'] != null) {
      for (var r in json['recent_reports'] as List) {
        recentList.add(Report.fromJson(r as Map<String, dynamic>));
      }
    }

    final previewList = <ReportMapItem>[];
    if (json['map_preview'] != null) {
      for (var m in json['map_preview'] as List) {
        previewList.add(ReportMapItem.fromJson(m as Map<String, dynamic>));
      }
    }

    return DashboardStats(
      totalReports: json['total_reports'] as int? ?? 0,
      newReports: json['new_reports'] as int? ?? 0,
      verifiedReports: json['verified_reports'] as int? ?? 0,
      assignedReports: json['assigned_reports'] as int? ?? 0,
      underRepairReports: json['under_repair_reports'] as int? ?? 0,
      resolvedReports: json['resolved_reports'] as int? ?? 0,
      priorityCounts: prioMap,
      topWilayas: wilayaList,
      recentReports: recentList,
      mapPreview: previewList,
    );
  }
}
