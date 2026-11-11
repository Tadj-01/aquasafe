import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../../models/administrator.dart';

class SupervisorService {
  /// List all administrator accounts and candidates with optional status filter
  static Future<List<Administrator>> listAdministrators({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status != 'ALL') {
      params['status_filter'] = status;
    }

    final response = await ApiClient.get(
      ApiConstants.administrators,
      queryParams: params.isNotEmpty ? params : null,
    );

    if (response is List) {
      return response
          .map((item) => Administrator.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get pending candidate count
  static Future<int> getPendingCount() async {
    try {
      final response = await ApiClient.get(ApiConstants.adminPendingCount);
      if (response is Map && response['pending_count'] != null) {
        return response['pending_count'] as int;
      }
    } catch (_) {}
    return 0;
  }

  /// Directly provision a new admin account
  static Future<Administrator> createAdministrator({
    required String name,
    required String email,
    required String password,
    String role = 'ADMIN',
  }) async {
    final response = await ApiClient.post(
      ApiConstants.administrators,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'is_active': true,
        'approval_status': 'APPROVED',
      },
    );
    return Administrator.fromJson(response as Map<String, dynamic>);
  }

  /// Supervisor decision: APPROVE or REJECT a candidate
  static Future<Administrator> reviewApplication({
    required String adminId,
    required String action, // "APPROVE" or "REJECT"
    String role = 'ADMIN',
  }) async {
    final response = await ApiClient.post(
      ApiConstants.administratorDecision(adminId),
      body: {
        'action': action,
        'role': role,
      },
    );
    return Administrator.fromJson(response as Map<String, dynamic>);
  }

  /// Update admin account (role, active state)
  static Future<Administrator> updateAdministrator(
    String adminId,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.patch(
      ApiConstants.administratorDetails(adminId),
      body: data,
    );
    return Administrator.fromJson(response as Map<String, dynamic>);
  }

  /// Delete an administrator account
  static Future<void> deleteAdministrator(String adminId) async {
    await ApiClient.delete(ApiConstants.administratorDetails(adminId));
  }
}
