import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../../models/administrator.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    final response = await ApiClient.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    );
    if (response is Map && response['access_token'] != null) {
      final token = response['access_token'] as String;
      await ApiClient.saveToken(token);
      return true;
    }
    return false;
  }

  static Future<void> signup(String name, String email, String password) async {
    await ApiClient.post(
      ApiConstants.signup,
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  static Future<bool> loginWithGoogle(String idToken) async {
    final response = await ApiClient.post(
      ApiConstants.googleLogin,
      body: {'id_token': idToken},
    );
    if (response is Map && response['access_token'] != null) {
      final token = response['access_token'] as String;
      await ApiClient.saveToken(token);
      return true;
    }
    return false;
  }

  static Future<Administrator?> getCurrentAdmin() async {
    final token = await ApiClient.getToken();
    if (token == null) return null;
    try {
      final response = await ApiClient.get(ApiConstants.me);
      if (response is Map<String, dynamic>) {
        return Administrator.fromJson(response);
      }
    } catch (_) {
      await ApiClient.clearToken();
    }
    return null;
  }

  static Future<Administrator> updateProfile({String? name, String? password}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (password != null) body['password'] = password;

    final response = await ApiClient.patch(ApiConstants.updateProfile, body: body);
    return Administrator.fromJson(response as Map<String, dynamic>);
  }

  static Future<void> logout() async {
    await ApiClient.clearToken();
  }

  static Future<bool> isAuthenticated() async {
    final token = await ApiClient.getToken();
    return token != null && token.isNotEmpty;
  }
}
