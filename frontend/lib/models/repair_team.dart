class RepairTeam {
  final String id;
  final String name;
  final String? description;
  final String? phone;
  final bool isActive;
  final String? leaderName;
  final String? leaderPhone;
  final String? wilayaCode;
  final String? wilayaName;
  final String? communeCode;
  final String? communeName;
  final double? latitude;
  final double? longitude;
  final String? specialization;
  final int? membersCount;
  final DateTime createdAt;

  RepairTeam({
    required this.id,
    required this.name,
    this.description,
    this.phone,
    required this.isActive,
    this.leaderName,
    this.leaderPhone,
    this.wilayaCode,
    this.wilayaName,
    this.communeCode,
    this.communeName,
    this.latitude,
    this.longitude,
    this.specialization,
    this.membersCount,
    required this.createdAt,
  });

  factory RepairTeam.fromJson(Map<String, dynamic> json) {
    return RepairTeam(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      leaderName: json['leader_name'] as String?,
      leaderPhone: json['leader_phone'] as String?,
      wilayaCode: json['wilaya_code'] as String?,
      wilayaName: json['wilaya_name'] as String?,
      communeCode: json['commune_code'] as String?,
      communeName: json['commune_name'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      specialization: json['specialization'] as String?,
      membersCount: json['members_count'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'phone': phone,
      'is_active': isActive,
      'leader_name': leaderName,
      'leader_phone': leaderPhone,
      'wilaya_code': wilayaCode,
      'wilaya_name': wilayaName,
      'commune_code': communeCode,
      'commune_name': communeName,
      'latitude': latitude,
      'longitude': longitude,
      'specialization': specialization,
      'members_count': membersCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
