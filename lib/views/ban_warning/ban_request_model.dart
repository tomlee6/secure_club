import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────
// BanRequestModel — GET /api/v1/bans/requests
// ─────────────────────────────────────────────────────
class BanRequestModel {
  final int id;
  final String personName;
  final String idNumber;
  final String reason;
  final String reasonCategory;
  final String banType;
  final String status;
  final String requestedBy;
  final String requestedAt;
  final int evidenceCount;
  final String? faceImageUrl;

  BanRequestModel({
    required this.id,
    required this.personName,
    required this.idNumber,
    required this.reason,
    required this.reasonCategory,
    required this.banType,
    required this.status,
    required this.requestedBy,
    required this.requestedAt,
    required this.evidenceCount,
    this.faceImageUrl,
  });

  factory BanRequestModel.fromJson(Map<String, dynamic> json) {
    String personName = json['person_name'] ?? '';
    if (personName.isEmpty && json['person'] != null) {
      final p = json['person'] as Map<String, dynamic>;
      personName = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    }

    String requestedBy = '';
    if (json['requested_by'] is String) {
      requestedBy = json['requested_by'];
    } else if (json['requested_by'] is Map) {
      requestedBy = (json['requested_by'] as Map)['name'] ?? '';
    }

    return BanRequestModel(
      id:             json['id']              ?? json['ban_id'] ?? 0,
      personName:     personName,
      idNumber:       json['id_number']       ?? '',
      reason:         json['reason']          ?? '',
      reasonCategory: json['reason_category'] ?? '',
      banType:        json['ban_type']        ?? '',
      status:         json['status']          ?? '',
      requestedBy:    requestedBy,
      requestedAt:    json['requested_at']    ?? json['created_at'] ?? '',
      evidenceCount:  json['evidence_count']  ?? 0,
      faceImageUrl:   json['face_image_url'],
    );
  }
}

// ─────────────────────────────────────────────────────
// ActiveBanModel — GET /api/v1/bans
// ─────────────────────────────────────────────────────
class ActiveBanModel {
  final int id;
  final String personName;
  final String idNumber;
  final String banType;
  final String banScope;
  final String status;
  final String? reason;
  final String? approvedBy;
  final String? requestedAt;
  final String? expiresAt;
  final String? faceImageUrl;

  ActiveBanModel({
    required this.id,
    required this.personName,
    required this.idNumber,
    required this.banType,
    required this.banScope,
    required this.status,
    this.reason,
    this.approvedBy,
    this.requestedAt,
    this.expiresAt,
    this.faceImageUrl,
  });

  factory ActiveBanModel.fromJson(Map<String, dynamic> json) {
    String personName = json['person_name'] ?? json['visitor_name'] ?? '';
    if (personName.isEmpty && json['person'] != null) {
      final p = json['person'] as Map<String, dynamic>;
      personName = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    }

    return ActiveBanModel(
      id:           json['id']           ?? 0,
      personName:   personName,
      idNumber:     json['id_number']    ?? '',
      banType:      json['ban_type']     ?? '',
      banScope:     json['ban_scope']    ?? 'club',
      status:       json['status']       ?? 'active',
      reason:       json['reason'],
      approvedBy:   json['approved_by'],
      requestedAt:  json['requested_at'] ?? json['banned_at'] ?? json['created_at'],
      expiresAt:    json['expires_at']   ?? json['ban_expiry_date'],
      faceImageUrl: json['face_image_url'],
    );
  }
}

// ─────────────────────────────────────────────────────
// GuardEntryModel — GET /api/v1/entries  (guard role)
// Used in Ban & Warning page when guard gets 403 on ban endpoints
// ─────────────────────────────────────────────────────
class GuardEntryModel {
  final int id;
  final String visitorName;
  final String idNumber;
  final String entryType;    // "entry" | "exit"
  final String status;       // "allowed" | "denied"
  final String? denialReason;
  final String loggedAt;
  final String? club;
  final String? guard;

  GuardEntryModel({
    required this.id,
    required this.visitorName,
    required this.idNumber,
    required this.entryType,
    required this.status,
    this.denialReason,
    required this.loggedAt,
    this.club,
    this.guard,
  });

  factory GuardEntryModel.fromJson(Map<String, dynamic> json) {
    return GuardEntryModel(
      id:           json['id']            ?? 0,
      visitorName:  json['visitor_name']  ?? '',
      idNumber:     json['id_number']     ?? '',
      entryType:    json['entry_type']    ?? 'entry',
      status:       json['status']        ?? '',
      denialReason: json['denial_reason'],
      loggedAt:     json['logged_at']     ?? '',
      club:         json['club'],
      guard:        json['guard'],
    );
  }
}

// ─────────────────────────────────────────────────────
// BanRequestsProvider
// ─────────────────────────────────────────────────────
class BanRequestsProvider extends ChangeNotifier {
  static const String _baseUrl = 'http://10.135.129.88:3000';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ══════════════════════════════════════════════════
  //  BAN REQUESTS  (Club Admin)
  //  GET /api/v1/bans/requests
  // ══════════════════════════════════════════════════
  bool _isLoadingBans = false;
  bool get isLoadingBans => _isLoadingBans;

  String? _banError;
  String? get banError => _banError;

  bool _banForbidden = false;
  bool get banForbidden => _banForbidden;

  List<BanRequestModel> _banRequests = [];
  List<BanRequestModel> get banRequests => _banRequests;

  int _banCurrentPage = 1;
  int get banCurrentPage => _banCurrentPage;
  int _banTotalPages = 1;
  int get banTotalPages => _banTotalPages;
  int _banTotal = 0;
  int get banTotal => _banTotal;

  Future<void> fetchBanRequests({
    required String token,
    int    page   = 1,
    String status = 'pending',
  }) async {
    _isLoadingBans = true;
    _banError      = null;
    _banForbidden  = false;
    notifyListeners();

    final url = Uri.parse(
      '$_baseUrl/api/v1/bans/requests?status=$status&page=$page&limit=20',
    );
    debugPrint('📤 GET BAN REQUESTS => $url');

    try {
      final response = await http.get(url, headers: _headers(token));
      debugPrint('📥 BAN REQUESTS STATUS: ${response.statusCode}');
      _prettyPrint(response.body);

      if (response.statusCode == 403) {
        _banForbidden  = true;
        _isLoadingBans = false;
        notifyListeners();
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final d    = data['data'] as Map<String, dynamic>;
        final list = d['requests'] ?? d['bans'] ?? [];
        _banRequests = (list as List<dynamic>)
            .map((e) => BanRequestModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final p = (d['pagination'] ?? {}) as Map<String, dynamic>;
        _banCurrentPage = p['page']        ?? 1;
        _banTotalPages  = p['total_pages'] ?? 1;
        _banTotal       = p['total']       ?? _banRequests.length;
        debugPrint('✅ Loaded ${_banRequests.length} ban requests (total: $_banTotal)');
      } else {
        _banError = data['error']?['message']
            ?? data['message']
            ?? 'Failed to load ban requests';
      }
    } catch (e) {
      _banError = 'Network error: $e';
      debugPrint('❌ fetchBanRequests exception: $e');
    }

    _isLoadingBans = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════
  //  ACTIVE BANS  (Club Admin only)
  //  GET /api/v1/bans
  // ══════════════════════════════════════════════════
  bool _isLoadingWarnings = false;
  bool get isLoadingWarnings => _isLoadingWarnings;

  String? _warningError;
  String? get warningError => _warningError;

  bool _warnForbidden = false;
  bool get warnForbidden => _warnForbidden;

  List<ActiveBanModel> _activeBans = [];
  List<ActiveBanModel> get activeBans => _activeBans;

  int _warnCurrentPage = 1;
  int get warnCurrentPage => _warnCurrentPage;
  int _warnTotalPages = 1;
  int get warnTotalPages => _warnTotalPages;
  int _warnTotal = 0;
  int get warnTotal => _warnTotal;

  Future<void> fetchActiveBans({
    required String token,
    int page = 1,
  }) async {
    _isLoadingWarnings = true;
    _warningError      = null;
    _warnForbidden     = false;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/api/v1/bans?page=$page&limit=20');
    debugPrint('📤 GET ACTIVE BANS => $url');

    try {
      final response = await http.get(url, headers: _headers(token));
      debugPrint('📥 ACTIVE BANS STATUS: ${response.statusCode}');
      _prettyPrint(response.body);

      if (response.statusCode == 403) {
        _warnForbidden     = true;
        _isLoadingWarnings = false;
        notifyListeners();
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final d    = data['data'] as Map<String, dynamic>;
        final list = d['bans'] ?? d['requests'] ?? [];
        _activeBans = (list as List<dynamic>)
            .map((e) => ActiveBanModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final p = (d['pagination'] ?? {}) as Map<String, dynamic>;
        _warnCurrentPage = p['page']        ?? 1;
        _warnTotalPages  = p['total_pages'] ?? 1;
        _warnTotal       = p['total']       ?? _activeBans.length;
        debugPrint('✅ Loaded ${_activeBans.length} active bans (total: $_warnTotal)');
      } else {
        _warningError = data['error']?['message']
            ?? data['message']
            ?? 'Failed to load active bans';
      }
    } catch (e) {
      _warningError = 'Network error: $e';
      debugPrint('❌ fetchActiveBans exception: $e');
    }

    _isLoadingWarnings = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════
  //  GUARD ENTRY LOGS  (Guard role — own scan history)
  //  GET /api/v1/entries
  //  Loaded for BOTH tabs when guard gets 403 on ban endpoints
  // ══════════════════════════════════════════════════
  bool _isLoadingEntries = false;
  bool get isLoadingEntries => _isLoadingEntries;

  String? _entriesError;
  String? get entriesError => _entriesError;

  List<GuardEntryModel> _guardEntries = [];
  List<GuardEntryModel> get guardEntries => _guardEntries;

  int _entriesCurrentPage = 1;
  int get entriesCurrentPage => _entriesCurrentPage;
  int _entriesTotalPages = 1;
  int get entriesTotalPages => _entriesTotalPages;
  int _entriesTotal = 0;
  int get entriesTotal => _entriesTotal;

  Future<void> fetchGuardEntryLogs({
    required String token,
    int     page      = 1,
    String? status,
    String? entryType,
    String? search,
  }) async {
    _isLoadingEntries = true;
    _entriesError     = null;
    notifyListeners();

    final params = <String, String>{
      'page':  '$page',
      'limit': '20',
      if (status    != null && status.isNotEmpty)    'status':     status,
      if (entryType != null && entryType.isNotEmpty) 'entry_type': entryType,
      if (search    != null && search.isNotEmpty)    'search':     search,
    };

    final url = Uri.parse('$_baseUrl/api/v1/entries')
        .replace(queryParameters: params);
    debugPrint('📤 GET GUARD ENTRIES => $url');

    try {
      final response = await http.get(url, headers: _headers(token));
      debugPrint('📥 GUARD ENTRIES STATUS: ${response.statusCode}');
      _prettyPrint(response.body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final d    = data['data'] as Map<String, dynamic>;
        final list = d['entries'] ?? [];
        _guardEntries = (list as List<dynamic>)
            .map((e) => GuardEntryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final p = (d['pagination'] ?? {}) as Map<String, dynamic>;
        _entriesCurrentPage = p['page']        ?? 1;
        _entriesTotalPages  = p['total_pages'] ?? 1;
        _entriesTotal       = p['total']       ?? _guardEntries.length;
        debugPrint('✅ Loaded ${_guardEntries.length} guard entries (total: $_entriesTotal)');
      } else {
        _entriesError = data['error']?['message']
            ?? data['message']
            ?? 'Failed to load entry logs';
      }
    } catch (e) {
      _entriesError = 'Network error: $e';
      debugPrint('❌ fetchGuardEntryLogs exception: $e');
    }

    _isLoadingEntries = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════
  //  Utilities
  // ══════════════════════════════════════════════════
  void clear() {
    _banRequests        = [];
    _activeBans         = [];
    _guardEntries       = [];
    _banCurrentPage     = 1;
    _banTotalPages      = 1;
    _banTotal           = 0;
    _warnCurrentPage    = 1;
    _warnTotalPages     = 1;
    _warnTotal          = 0;
    _entriesCurrentPage = 1;
    _entriesTotalPages  = 1;
    _entriesTotal       = 0;
    _isLoadingBans      = false;
    _isLoadingWarnings  = false;
    _isLoadingEntries   = false;
    _banError           = null;
    _warningError       = null;
    _entriesError       = null;
    _banForbidden       = false;
    _warnForbidden      = false;
    notifyListeners();
  }

  void _prettyPrint(String body) {
    try {
      final pretty =
      const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
      for (int i = 0; i < pretty.length; i += 800) {
        debugPrint(pretty.substring(
            i, i + 800 > pretty.length ? pretty.length : i + 800));
      }
    } catch (_) {
      debugPrint(body);
    }
  }
}