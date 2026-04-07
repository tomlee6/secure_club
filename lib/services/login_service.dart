import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class LoginService {
  static  String baseUrl = ApiConstants.baseUrl;

  Future<Map<String, dynamic>> login(String email, String password, String deviceUuid) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/guard/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_uuid': 'A1B2C3D4-E8F9-1234', // Hardcoded
          'device_token': 'dummy_web_device_token_123', // Hardcoded
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('--- LOGIN API SUCCESS RESPONSE ---');
        print(response.body);
        print('----------------------------------');

        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final Map<String, dynamic> payload = Map<String, dynamic>.from(responseData['data'] ?? {});
          final Map<String, dynamic> userMap = Map<String, dynamic>.from(payload['user'] ?? {});
          return {
            'success': true,
            'access_token': payload['access_token'],
            'refresh_token': payload['refresh_token'],
            'expires_in': payload['expires_in'],
            'user': UserModel.fromJson(userMap),
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Login failed.',
          };
        }
      } else {
        print('--- LOGIN API FAILED RESPONSE ---');
        print(response.body);
        print('---------------------------------');
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? errorData['error']?['message'] ?? 'Invalid credentials.',
        };
      }
    } catch (e) {
      print('--- LOGIN API ERROR ---');
      print(e);
      print('-----------------------');
      return {
        'success': false,
        'message': 'Network error: Please check your connection.',
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] == true,
          'message': responseData['data']?['message'] ?? 'If this email exists, a reset link has been sent.',
        };
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? errorData['error']?['message'] ?? 'Failed to send reset link.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: Please check your connection.',
      };
    }
  }

  Future<bool> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('--- LOGOUT API RESPONSE ---');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('---------------------------');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('--- LOGOUT API ERROR ---');
      print(e);
      print('------------------------');
      return false;
    }
  }
}

