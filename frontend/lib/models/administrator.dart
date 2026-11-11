class Administrator {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String approvalStatus; // "PENDING", "APPROVED", "REJECTED"
  final String signupSource;   // "EMAIL", "GOOGLE", "MANUAL_PROVISION"
  final DateTime createdAt;

  Administrator({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.approvalStatus = 'APPROVED',
    this.signupSource = 'EMAIL',
    required this.createdAt,
  });

  bool get isSupervisor => role.toUpperCase() == 'SUPERVISOR';
  bool get isPending => approvalStatus.toUpperCase() == 'PENDING';
  bool get isApproved => approvalStatus.toUpperCase() == 'APPROVED';
  bool get isRejected => approvalStatus.toUpperCase() == 'REJECTED';

  factory Administrator.fromJson(Map<String, dynamic> json) {
    return Administrator(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'ADMIN',
      isActive: json['is_active'] as bool? ?? true,
      approvalStatus: json['approval_status'] as String? ?? 'APPROVED',
      signupSource: json['signup_source'] as String? ?? 'EMAIL',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
      'approval_status': approvalStatus,
      'signup_source': signupSource,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
