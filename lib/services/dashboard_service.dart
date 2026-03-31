import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  static const String baseUrl = 'http://10.248.36.46:3000';

  Future<Map<String, dynamic>> fetchStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/dashboard/guard/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('--- DASHBOARD STATS API RESPONSE ---');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('------------------------------------');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
          };
        }
      }
      return {'success': false, 'message': 'Failed to fetch dashboard stats'};
    } catch (e) {
      print('Dashboard API error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }
}
