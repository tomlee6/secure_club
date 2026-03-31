import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../models/entry_scan_result.dart';
import '../services/scan_service.dart';

class EntryScanViewModel extends ChangeNotifier {
  final ScanService _apiService = ScanService();

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _isFaceCaptured = false;
  bool get isFaceCaptured => _isFaceCaptured;

  XFile? _capturedImage;
  XFile? get capturedImage => _capturedImage;

  EntryScanResult? _scanResult;
  EntryScanResult? get scanResult => _scanResult;

  Future<void> scanQrCode(String qrData, String token) async {
    if (qrData.isNotEmpty) {
      _isScanning = true;
      notifyListeners();
      
      try {
        _scanResult = await _apiService.verifyQrCode(qrData, token);
      } finally {
        _isScanning = false;
        notifyListeners();
      }
    }
  }

  Future<void> setCapturedPhoto(XFile? photo) async {
    if (photo != null) {
      _capturedImage = photo;
      _isFaceCaptured = true;
      notifyListeners();
    }
  }

  void retakePhoto() {
    _isFaceCaptured = false;
    _capturedImage = null;
    _scanResult = null;
    notifyListeners();
  }

  Future<void> processEntry(String token) async {
    if (_isFaceCaptured && _capturedImage != null && _scanResult != null) {
      if (_scanResult!.scanId == null || _scanResult!.personIdNumber == null) {
         print("Error: Missing scanId or personIdNumber from QR Scan");
         return;
      }

      _isScanning = true;
      notifyListeners();

      try {
        // 1. Capture Face API
        final captureRes = await _apiService.captureFace(
          _capturedImage!,
          _scanResult!.scanId!,
          _scanResult!.personIdNumber!,
          token
        );

        if (captureRes != null && captureRes['face_id'] != null) {
          int faceId = int.parse(captureRes['face_id'].toString());
          // 2. Match Face API
          final matchRes = await _apiService.matchFace(
            faceId,
            _scanResult!.scanId!,
            token
          );

          if (matchRes != null && matchRes['match_score'] != null) {
            _scanResult!.faceMatchScore = matchRes['match_score'].toString() + '%';
          } else {
            _scanResult!.faceMatchScore = 'Match failed';
          }
        } else {
          _scanResult!.faceMatchScore = 'Capture failed';
        }
      } catch (e) {
        print("processEntry error: $e");
        _scanResult!.faceMatchScore = 'Error';
      } finally {
        _isScanning = false;
        notifyListeners();
      }
    }
  }
}
