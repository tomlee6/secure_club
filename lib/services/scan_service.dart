import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/entry_scan_result.dart';

class ScanService {
  static const String baseUrl = 'http://10.248.36.46:3000';

  Future<EntryScanResult?> verifyQrCode(String qrData, String token) async {
    print('--- INITIATING QR SCAN VERIFY ---');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/scan/qr-verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "qr_data": qrData,
          "id_type": "passport",
          "device_id": 1
        }),
      ).timeout(const Duration(seconds: 15));

      print('--- SCAN QR VERIFY API RESPONSE ---');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('-----------------------------------');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          final data = responseData['data'] ?? {};
          final person = data['person'] ?? {};
          
          final now = DateTime.now();
          final formattedDate = "${now.day}/${now.month}/${now.year}";
          final formattedTime = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

          final banDetails = data['ban_details'] ?? data['active_ban'] ?? {};

          return EntryScanResult(
            name: '${person["first_name"] ?? ""} ${person["last_name"] ?? ""}'.trim(),
            dob: person["date_of_birth"]?.toString() ?? 'N/A',
            address: person["id_state"]?.toString() ?? 'N/A',
            idNo: person["id_number"]?.toString() ?? 'N/A',
            idExpiry: 'N/A',
            faceMatchScore: 'N/A',
            entryTime: '$formattedDate $formattedTime',
            verificationStatus: data['verification'] ?? 'ALLOWED',
            scanId: data['scan_id'] != null ? int.tryParse(data['scan_id'].toString()) : null,
            personIdNumber: person["id_number"]?.toString(),
            banStatus: banDetails['status']?.toString().toUpperCase() ?? 'ACTIVE BAN',
            banReason: banDetails['reason']?.toString() ?? 'Aggressive behavior',
            bannedBy: banDetails['banned_by']?.toString() ?? 'Mamao Club',
            banExpiry: banDetails['expiry']?.toString() ?? 'Permanent',
          );
        }
      }
    } catch (e) {
      print('--- SCAN API ERROR ---');
      print(e);
      print('----------------------');
    }
    return null;
  }

  Future<Map<String, dynamic>?> captureFace(XFile imageFile, int scanId, String personIdNumber, String token) async {
    print('--- INITIATING FACE CAPTURE ---');
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/v1/scan/face-capture'));
      request.headers['Authorization'] = 'Bearer $token';

      final bytes = await imageFile.readAsBytes();
      String filename = imageFile.name;
      if (filename.isEmpty) {
        filename = 'face_capture.jpg';
      } else if (!filename.contains('.')) {
        filename = '$filename.jpg';
      }

      request.files.add(http.MultipartFile.fromBytes(
        'face_image',
        bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));
      
      request.fields['scanned_id_ref'] = scanId.toString();
      request.fields['person_id_number'] = personIdNumber;
      request.fields['light_condition'] = 'normal';

      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      print('--- FACE CAPTURE API RESPONSE ---');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('---------------------------------');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data']; // Contains face_id, face_image_url
        }
      }
    } catch (e) {
      print('--- FACE CAPTURE API ERROR ---');
      print(e);
      print('------------------------------');
    }
    return null;
  }

  Future<Map<String, dynamic>?> matchFace(int faceId, int scanId, String token) async {
    print('--- INITIATING FACE MATCH ---');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/scan/face-match'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "face_id": faceId.toString(),
          "scanned_id_ref": scanId.toString(),
          "check_ban_faces": true
        }),
      ).timeout(const Duration(seconds: 15));

      print('--- FACE MATCH API RESPONSE ---');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('-------------------------------');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data']; // Contains match_score, is_match
        }
      }
    } catch (e) {
      print('--- FACE MATCH API ERROR ---');
      print(e);
      print('----------------------------');
    }
    return null;
  }
}
