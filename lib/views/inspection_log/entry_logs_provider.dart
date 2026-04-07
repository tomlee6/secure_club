



import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EntryLogModel {
  final int id;
  final String visitorName;
  final String idNumber;
  final String club;
  final String guard;
  final String entryType;    // "entry" | "exit"
  final String status;       // "allowed" | "denied"
  final String? denialReason;
  final String loggedAt;

  EntryLogModel({
    required this.id,
    required this.visitorName,
    required this.idNumber,
    required this.club,
    required this.guard,
    required this.entryType,
    required this.status,
    this.denialReason,
    required this.loggedAt,
  });

  factory EntryLogModel.fromJson(Map<String, dynamic> json) {
    return EntryLogModel(
      id:           json['id']           ?? 0,
      visitorName:  json['visitor_name'] ?? '',
      idNumber:     json['id_number']    ?? '',
      club:         json['club']         ?? '',
      guard:        json['guard']        ?? '',
      entryType:    json['entry_type']   ?? '',
      status:       json['status']       ?? '',
      denialReason: json['denial_reason'],
      loggedAt:     json['logged_at']    ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────
class EntryLogsProvider extends ChangeNotifier {
  static const String _baseUrl = 'http://10.58.205.46:3000/api/v1';
  // static const String _baseUrl = 'ApiConstants.baseUrl/api/v1';
  static const int    _limit   = 20;

  // ── GET state ──
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── POST state ──
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  // ── Messages ──
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // ── Data ──
  List<EntryLogModel> _entries = [];
  List<EntryLogModel> get entries => _entries;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  int _total = 0;
  int get total => _total;

  // ── Shared headers builder ──
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ─────────────────────────────────────────────────────────
  // GET /api/v1/entries
  // Role: guard, club_admin
  // ─────────────────────────────────────────────────────────
  Future<void> fetchEntryLogs({
    required String token,
    int     page      = 1,
    String? status,       // optional: 'allowed' | 'denied'
    String? entryType,    // optional: 'entry' | 'exit'
    String? search,       // optional: search by name or ID
  }) async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    final queryParams = {
      'page':  '$page',
      'limit': '$_limit',
      if (status    != null && status.isNotEmpty)    'status':     status,
      if (entryType != null && entryType.isNotEmpty) 'entry_type': entryType,
      if (search    != null && search.isNotEmpty)    'search':     search,
    };

    final url = Uri.parse('$_baseUrl/entries')
        .replace(queryParameters: queryParams);

    try {
      debugPrint('📤 GET ENTRIES => $url');

      final response = await http.get(url, headers: _headers(token));

      debugPrint('📥 EntryLogs STATUS: ${response.statusCode}');
      debugPrint('📥 EntryLogs BODY: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final d          = data['data'];
        final pagination = d['pagination'];
        _entries     = (d['entries'] as List<dynamic>)
            .map((e) => EntryLogModel.fromJson(e))
            .toList();
        _currentPage  = pagination['page']        ?? 1;
        _totalPages   = pagination['total_pages'] ?? 1;
        _total        = pagination['total']       ?? 0;
        _errorMessage = null;
      } else {
        // handles both { error: { message } } and { message } shapes
        _errorMessage = data['error']?['message']
            ?? data['message']
            ?? 'Failed to load entry logs';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      debugPrint('❌ fetchEntryLogs error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // POST /api/v1/entries
  // Role: guard
  // Returns true on success, false on failure
  // ─────────────────────────────────────────────────────────
  Future<bool> createEntry({
    required String token,
    required String visitorName,
    required String idNumber,
    required String idState,
    required String entryType,     // "entry" | "exit"
    required String status,        // "allowed" | "denied"
    String? denialReason,          // required when status == "denied"
    double? faceMatchScore,
    int?    scannedIdRef,
    int?    banId,
    String? notes,
  }) async {
    _isSubmitting   = true;
    _errorMessage   = null;
    _successMessage = null;
    notifyListeners();

    // Build body — only include optional fields when they have values
    final body = <String, dynamic>{
      'visitor_name': visitorName,
      'id_number':    idNumber,
      'id_state':     idState,
      'entry_type':   entryType,
      'status':       status,
    };

    if (scannedIdRef   != null) body['scanned_id_ref']   = scannedIdRef;
    if (denialReason   != null) body['denial_reason']    = denialReason;
    if (faceMatchScore != null) body['face_match_score'] = faceMatchScore;
    if (banId          != null) body['ban_id']           = banId;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📤 CREATE ENTRY LOG — BODY:');
      debugPrint(const JsonEncoder.withIndent('  ').convert(body));

      final response = await http.post(
        Uri.parse('$_baseUrl/entries'),
        headers: _headers(token),
        body:    jsonEncode(body),
      );

      debugPrint('📥 CREATE ENTRY — RESPONSE [${response.statusCode}]:');
      debugPrint(response.body);
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _successMessage = 'Visit recorded successfully!';
        debugPrint('✅ Entry created! entry_id=${data['data']['entry_id']}');
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['error']?['message']
            ?? data['message']
            ?? 'Failed to record visit';
        _isSubmitting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      debugPrint('❌ createEntry error: $e');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // Utilities
  // ─────────────────────────────────────────────────────────

  /// Call after reading successMessage/errorMessage to avoid re-triggering
  void clearMessages() {
    _errorMessage   = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Call on logout to wipe all data
  void clear() {
    _entries        = [];
    _currentPage    = 1;
    _totalPages     = 1;
    _total          = 0;
    _isLoading      = false;
    _isSubmitting   = false;
    _errorMessage   = null;
    _successMessage = null;
    notifyListeners();
  }
}