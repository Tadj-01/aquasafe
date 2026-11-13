class Wilaya {
  final String code;
  final String nameFr;
  final String nameAr;

  Wilaya({
    required this.code,
    required this.nameFr,
    required this.nameAr,
  });

  factory Wilaya.fromJson(Map<String, dynamic> json) {
    return Wilaya(
      code: json['code'] as String,
      nameFr: json['name_fr'] as String,
      nameAr: json['name_ar'] as String,
    );
  }

  String get displayName => '$code - $nameFr ($nameAr)';
}

class Commune {
  final String code;
  final String wilayaCode;
  final String nameFr;
  final String nameAr;

  Commune({
    required this.code,
    required this.wilayaCode,
    required this.nameFr,
    required this.nameAr,
  });

  factory Commune.fromJson(Map<String, dynamic> json) {
    return Commune(
      code: json['code'] as String,
      wilayaCode: json['wilaya_code'] as String,
      nameFr: json['name_fr'] as String,
      nameAr: json['name_ar'] as String,
    );
  }

  String get displayName => '$nameFr ($nameAr)';
}

class GeoSearchResult {
  final String communeCode;
  final String communeNameFr;
  final String communeNameAr;
  final String wilayaCode;
  final String wilayaNameFr;
  final String wilayaNameAr;
  final double? latitude;
  final double? longitude;
  final int score;

  GeoSearchResult({
    required this.communeCode,
    required this.communeNameFr,
    required this.communeNameAr,
    required this.wilayaCode,
    required this.wilayaNameFr,
    required this.wilayaNameAr,
    this.latitude,
    this.longitude,
    required this.score,
  });

  factory GeoSearchResult.fromJson(Map<String, dynamic> json) {
    return GeoSearchResult(
      communeCode: json['commune_code'] as String? ?? '',
      communeNameFr: json['commune_name_fr'] as String? ?? '',
      communeNameAr: json['commune_name_ar'] as String? ?? '',
      wilayaCode: json['wilaya_code'] as String? ?? '',
      wilayaNameFr: json['wilaya_name_fr'] as String? ?? '',
      wilayaNameAr: json['wilaya_name_ar'] as String? ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      score: json['score'] as int? ?? 0,
    );
  }
}
