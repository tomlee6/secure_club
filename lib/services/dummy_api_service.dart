import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ban_request_model.dart';
import '../models/entry_scan_result.dart';

class DummyApiService {




  Future<EntryScanResult?> verifyQrCode(String qrData) async {
    try {
      final url = Uri.parse('http://localhost:8080/api/v1/scan/qr-verify'); // Example URL
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "qr_data": qrData,
          "id_type": "drivers_license",
          "device_id": 1
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final person = data['person'];
        return EntryScanResult(
          name: '${person["first_name"]} ${person["last_name"]}',
          dob: person["date_of_birth"],
          address: person["id_state"],
          idNo: person["id_number"],
          idExpiry: 'N/A',
          faceMatchScore: 'N/A', // Since we only scanned ID
          entryTime: DateTime.now().toString().substring(0, 16), verificationStatus: '',
        );
      }
    } catch (e) {
      print('API Error: $e');
    }
    
    // Fallback parser if API isn't accessible
    final parts = qrData.split('|');
    if (parts.length >= 6) {
      return EntryScanResult(
        name: '${parts[4]} ${parts[3]}',
        dob: parts[5],
        address: parts[0],
        idNo: parts[2],
        idExpiry: 'Unknown',
        faceMatchScore: 'N/A',
        entryTime: DateTime.now().toString().substring(0, 16), verificationStatus: '',
      );
    }
    return null;
  }
}
