import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ban_request_model.dart';

class BanWarningService {
  static const String baseUrl = 'http://10.248.36.46:3000';

  Future<Map<String, dynamic>> getBanRequests({
    required String token,
    int page = 1,
    int limit = 20,
    String search = '',
    String startDate = '',
    String endDate = '',
  }) async {
    print('--- INITIATING GET BAN REQUESTS API ---');
    try {
      final queryParams = {
        'status': 'pending',
        'page': page.toString(),
        'limit': limit.toString(),
        if (search.isNotEmpty) 'search': search,
        if (startDate.isNotEmpty) 'start_date': startDate,
        if (endDate.isNotEmpty) 'end_date': endDate,
      };

      final uri = Uri.parse('$baseUrl/api/v1/bans/requests').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('--- BAN REQUESTS API RESPONSE ---');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('-----------------------------------');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final Map<String, dynamic> dataMap = responseData['data'] ?? {};
          final List entriesList = dataMap['requests'] ?? [];
          final pagination = dataMap['pagination'] ?? {};
          final totalPages = pagination['total_pages'] ?? 1;
          final currentPage = pagination['page'] ?? 1;

          final items = entriesList.map((item) {
            final name = item['person_name']?.toString() ?? 'Unknown';
            final duration = item['ban_type']?.toString() ?? 'Unknown';
            final dateStr = item['requested_at']?.toString() ?? '';
            final date = dateStr.isNotEmpty ? dateStr.split('T').first : 'Unknown';
            
            return BanRequestModel(
              id: item['id']?.toString() ?? '0',
              name: name,
              banDuration: duration,
              requestedOn: date,
              // Detail Page Properties mapped back safely to requests schema
              personName: name,
              idNumber: item['id_number']?.toString() ?? '',
              banType: duration,
              status: item['status']?.toString() ?? '',
              reason: item['reason']?.toString(),
              reasonCategory: item['reason_category']?.toString() ?? '',
              requestedBy: item['requested_by']?.toString() ?? '',
              requestedAt: dateStr,
              evidenceCount: item['evidence_count'] is int ? item['evidence_count'] : (int.tryParse(item['evidence_count']?.toString() ?? '0') ?? 0),
              faceImageUrl: item['face_image_url']?.toString(),
              description: item['description']?.toString(),
              banExpiryDate: item['ban_expiry_date']?.toString(),
            );
          }).toList();
          
          return {
            'items': items,
            'totalPages': totalPages,
            'currentPage': currentPage,
          };
        }
      }
    } catch (e) {
      print('--- BAN REQUESTS ERROR ---');
      print(e);
      print('--------------------------');
    }
    return {'items': <BanRequestModel>[], 'totalPages': 1, 'currentPage': 1};
  }

  Future<bool> deleteWarning({required String warningId, required String token}) async {
    print('--- INITIATING DELETE WARNING API ---');
    try {
      final uri = Uri.parse('$baseUrl/api/v1/bans/warnings/$warningId');
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('--- DELETE WARNING API RESPONSE ---');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      }
    } catch (e) {
      print('--- DELETE WARNING ERROR ---');
      print(e);
    }
    return false;
  }

  Future<Map<String, dynamic>> getWarnings({
    required String token,
    int page = 1,
    int limit = 20,
    String search = '',
    String startDate = '',
    String endDate = '',
  }) async {
    print('--- INITIATING GET WARNINGS API ---');
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search.isNotEmpty) 'search': search,
        if (startDate.isNotEmpty) 'start_date': startDate,
        if (endDate.isNotEmpty) 'end_date': endDate,
      };
      
      final uri = Uri.parse('$baseUrl/api/v1/bans/warnings').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('--- WARNINGS API RESPONSE ---');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('-----------------------------------');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final Map<String, dynamic> dataMap = responseData['data'] ?? {};
          final List entriesList = dataMap['warnings'] ?? [];
          final totalPages = (dataMap['total'] != null && dataMap['limit'] != null) 
              ? (dataMap['total'] / dataMap['limit']).ceil() 
              : 1;
          final currentPage = dataMap['page'] ?? 1;

          final items = entriesList.map((item) {
            final name = item['visitor_name']?.toString() ?? "${item['first_name'] ?? ''} ${item['last_name'] ?? ''}".trim();
            final reason = item['denial_reason']?.toString() ?? 'No Reason';
            final dateStr = item['created_at']?.toString() ?? '';
            final date = dateStr.isNotEmpty ? dateStr.split('T').first : 'Unknown';
            
            return WarningModel(
              id: item['id']?.toString() ?? '0',
              name: name.isEmpty ? 'Unknown' : name,
              warningReason: reason,
              date: date,
              // New details specific to Warning schema
              idNumber: item['id_number']?.toString() ?? '',
              guardName: item['guard_name']?.toString() ?? '',
              createdAt: dateStr,
              warningCount: item['warning_count'] is int ? item['warning_count'] : int.tryParse(item['warning_count']?.toString() ?? '0') ?? 0,
            );
          }).toList();
          
          return {
            'items': items,
            'totalPages': totalPages,
            'currentPage': currentPage,
          };
        }
      }
    } catch (e) {
      print('--- WARNINGS ERROR ---');
      print(e);
      print('--------------------------');
    }
    return {'items': <WarningModel>[], 'totalPages': 1, 'currentPage': 1};
  }
}
