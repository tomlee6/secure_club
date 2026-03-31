import 'dart:async';
import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  Timer? _clockTimer;

  DashboardViewModel() {
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  int _activeBans = 0;
  int _todayEntries = 0;
  int _pendingBanReq = 0;
  int _todayAllowed = 0;
  int _todayDenied = 0;
  String? _shiftStart;
  String? _clubName;
  String? _timestamp;

  bool _isLoading = false;

  int get activeBans => _activeBans;
  int get todayEntries => _todayEntries;
  int get pendingBanReq => _pendingBanReq;
  int get todayAllowed => _todayAllowed;
  int get todayDenied => _todayDenied;
  String? get shiftStart => _shiftStart;
  String? get clubName => _clubName;
  bool get isLoading => _isLoading;
  String? get timestamp => _timestamp;

  String get formattedTime {
    final dateTime = DateTime.now();
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return "$hour:${dateTime.minute.toString().padLeft(2, '0')} $amPm";
  }

  int _entryCount = 0; // Local counter if needed

  String get formattedEntryCount => _entryCount.toString().padLeft(3, '0');

  Future<void> fetchDashboardStats(String token) async {
    _isLoading = true;
    notifyListeners();

    final result = await _dashboardService.fetchStats(token);
    
    if (result['success'] == true) {
      final data = result['data'];
      final meta = result['meta'];
      _todayEntries = data['today_entries'] ?? 0;
      _todayDenied = data['today_denied'] ?? 0;
      _todayAllowed = data['today_allowed'] ?? 0;
      _pendingBanReq = data['pending_bans'] ?? 0;
      _activeBans = data['active_bans'] ?? 0;
      _shiftStart = data['shift_start'];
      _clubName = data['club']?['name'];
      _timestamp = meta?['timestamp'];
    }

    _isLoading = false;
    notifyListeners();
  }

  void incrementEntry() {
    _entryCount++;
    notifyListeners();
  }

  void decrementEntry() {
    if (_entryCount > 0) {
      _entryCount--;
      notifyListeners();
    }
  }
}
