import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_exception.dart';

class ApiClient {
  static const String _tokenKey = 'aquasafe_auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool isJson = true}) async {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return json.decode(utf8.decode(response.bodyBytes));
      } catch (e) {
        return response.body;
      }
    }

    String errorMessage = 'Request failed with status ${response.statusCode}';
    try {
      final errorJson = json.decode(utf8.decode(response.bodyBytes));
      if (errorJson is Map && errorJson['detail'] != null) {
        errorMessage = errorJson['detail'].toString();
      }
    } catch (_) {}

    throw ApiException(errorMessage, response.statusCode);
  }

  static Future<dynamic> get(String url, {Map<String, dynamic>? queryParams}) async {
    var uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = <String, String>{};
      queryParams.forEach((k, v) {
        if (v != null) stringParams[k] = v.toString();
      });
      uri = uri.replace(queryParameters: stringParams);
    }

    try {
      final headers = await _headers();
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection error: ${e.toString()}');
    }
  }

  static Future<dynamic> post(String url, {dynamic body}) async {
    try {
      final headers = await _headers();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection error: ${e.toString()}');
    }
  }

  static Future<dynamic> patch(String url, {dynamic body}) async {
    try {
      final headers = await _headers();
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection error: ${e.toString()}');
    }
  }

  static Future<dynamic> delete(String url) async {
    try {
      final headers = await _headers();
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection error: ${e.toString()}');
    }
  }

  static Future<dynamic> postMultipart({
    required String url,
    required Map<String, String> fields,
    required String fileField,
    required List<int> fileBytes,
    required String filename,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      // Add text fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add auth header if present
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Determine proper mime content type
      String sanitizedFilename = filename;
      final lowerName = filename.toLowerCase();
      MediaType mediaType;

      if (lowerName.endsWith('.png')) {
        mediaType = MediaType('image', 'png');
      } else if (lowerName.endsWith('.webp')) {
        mediaType = MediaType('image', 'webp');
      } else if (lowerName.endsWith('.jpeg') || lowerName.endsWith('.jpg')) {
        mediaType = MediaType('image', 'jpeg');
      } else {
        // Default to JPEG if extension missing or unknown
        sanitizedFilename = '$filename.jpg';
        mediaType = MediaType('image', 'jpeg');
      }

      // Add multipart file from bytes with explicit image MIME type
      final multipartFile = http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: sanitizedFilename,
        contentType: mediaType,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to upload report: ${e.toString()}');
    }
  }
}
