import 'repair_team.dart';

class StatusHistoryItem {
  final String id;
  final String reportId;
  final String? oldStatus;
  final String newStatus;
  final String? changedBy;
  final DateTime changedAt;
  final String? note;

  StatusHistoryItem({
    required this.id,
    required this.reportId,
    this.oldStatus,
    required this.newStatus,
    this.changedBy,
    required this.changedAt,
    this.note,
  });

  factory StatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItem(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String,
      changedBy: json['changed_by'] as String?,
      changedAt: DateTime.parse(json['changed_at'] as String),
      note: json['note'] as String?,
    );
  }
}

class Report {
  final String id;
  final double latitude;
  final double longitude;
  final double? gpsAccuracy;
  final String photoUrl;
  final String? note;
  final String? wilayaCode;
  final String? wilayaName;
  final String? communeCode;
  final String? communeName;
  final String status;
  final String priority;
  final String? assignedTeamId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final RepairTeam? assignedTeam;
  final List<StatusHistoryItem> statusHistory;

  Report({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.gpsAccuracy,
    required this.photoUrl,
    this.note,
    this.wilayaCode,
    this.wilayaName,
    this.communeCode,
    this.communeName,
    required this.status,
    required this.priority,
    this.assignedTeamId,
    required this.createdAt,
    this.updatedAt,
    this.assignedTeam,
    this.statusHistory = const [],
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    var historyList = <StatusHistoryItem>[];
    if (json['status_history'] != null) {
      historyList = (json['status_history'] as List)
          .map((i) => StatusHistoryItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    RepairTeam? team;
    if (json['assigned_team'] != null) {
      team = RepairTeam.fromJson(json['assigned_team'] as Map<String, dynamic>);
    }

    return Report(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      gpsAccuracy: json['gps_accuracy'] != null
          ? (json['gps_accuracy'] as num).toDouble()
          : null,
      photoUrl: json['photo_url'] as String,
      note: json['note'] as String?,
      wilayaCode: json['wilaya_code'] as String?,
      wilayaName: json['wilaya_name'] as String?,
      communeCode: json['commune_code'] as String?,
      communeName: json['commune_name'] as String?,
      status: json['status'] as String? ?? 'NEW',
      priority: json['priority'] as String? ?? 'NORMAL',
      assignedTeamId: json['assigned_team_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      assignedTeam: team,
      statusHistory: historyList,
    );
  }
}

class ReportMapItem {
  final String id;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final String? note;
  final String status;
  final String priority;
  final String? wilayaName;
  final String? communeName;
  final DateTime createdAt;

  ReportMapItem({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.photoUrl,
    this.note,
    required this.status,
    required this.priority,
    this.wilayaName,
    this.communeName,
    required this.createdAt,
  });

  factory ReportMapItem.fromJson(Map<String, dynamic> json) {
    return ReportMapItem(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      photoUrl: json['photo_url'] as String,
      note: json['note'] as String?,
      status: json['status'] as String? ?? 'NEW',
      priority: json['priority'] as String? ?? 'NORMAL',
      wilayaName: json['wilaya_name'] as String?,
      communeName: json['commune_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ReportConfirmation {
  final String id;
  final String status;
  final String priority;
  final double latitude;
  final double longitude;
  final String? wilayaCode;
  final String? wilayaName;
  final String? communeCode;
  final String? communeName;
  final DateTime createdAt;
  final String message;

  ReportConfirmation({
    required this.id,
    required this.status,
    required this.priority,
    required this.latitude,
    required this.longitude,
    this.wilayaCode,
    this.wilayaName,
    this.communeCode,
    this.communeName,
    required this.createdAt,
    required this.message,
  });

  factory ReportConfirmation.fromJson(Map<String, dynamic> json) {
    return ReportConfirmation(
      id: json['id'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      wilayaCode: json['wilaya_code'] as String?,
      wilayaName: json['wilaya_name'] as String?,
      communeCode: json['commune_code'] as String?,
      communeName: json['commune_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      message: json['message'] as String? ?? 'Report submitted successfully.',
    );
  }
}
