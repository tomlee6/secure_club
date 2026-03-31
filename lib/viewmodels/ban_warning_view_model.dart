import 'package:flutter/material.dart';
import '../models/ban_request_model.dart';
import '../services/ban_warning_service.dart';

class BanWarningViewModel extends ChangeNotifier {
  final BanWarningService _apiService = BanWarningService();

  int _selectedTabIndex = 0; // 0 for Ban Request, 1 for Warning
  int get selectedTabIndex => _selectedTabIndex;

  List<BanRequestModel> _banRequests = [];
  List<BanRequestModel> get banRequests => _banRequests;
  int _banCurrentPage = 1;
  int _banTotalPages = 1;

  List<WarningModel> _warnings = [];
  List<WarningModel> get warnings => _warnings;
  int _warnCurrentPage = 1;
  int _warnTotalPages = 1;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Filters State
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  DateTime? _fromDate;
  DateTime? get fromDate => _fromDate;

  DateTime? _toDate;
  DateTime? get toDate => _toDate;

  String _selectedTime = 'All';
  String get selectedTime => _selectedTime;

  String _selectedType = 'All';
  String get selectedType => _selectedType;

  void setSearchQuery(String query, String token) {
    _searchQuery = query;
    _resetPagesAndFetch(token);
  }

  void setFromDate(DateTime? date, String token) {
    _fromDate = date;
    _resetPagesAndFetch(token);
  }

  void setToDate(DateTime? date, String token) {
    _toDate = date;
    _resetPagesAndFetch(token);
  }

  void setTimeFilter(String time, String token) {
    _selectedTime = time;
    _resetPagesAndFetch(token);
  }

  void setTypeFilter(String type, String token) {
    _selectedType = type;
    _resetPagesAndFetch(token);
  }

  void clearFilters(String token) {
    _searchQuery = '';
    _fromDate = null;
    _toDate = null;
    _selectedTime = 'All';
    _selectedType = 'All';
    _resetPagesAndFetch(token);
  }

  void _resetPagesAndFetch(String token) {
    if (_selectedTabIndex == 0) {
      _banCurrentPage = 1;
      fetchBanRequests(token);
    } else {
      _warnCurrentPage = 1;
      fetchWarnings(token);
    }
  }

  void setTabIndex(int index, String token) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
      if (index == 0 && _banRequests.isEmpty) {
        fetchBanRequests(token);
      } else if (index == 1 && _warnings.isEmpty) {
        fetchWarnings(token);
      }
    }
  }

  Future<void> fetchBanRequests(String token) async {
    _isLoading = true;
    notifyListeners();

    String sd = '';
    String ed = '';
    final now = DateTime.now();

    if (_selectedTime == 'All') {
      sd = '';
      ed = '';
    } else if (_selectedTime == 'Today') {
      sd = DateTime(now.year, now.month, now.day).toIso8601String().split('T').first;
      ed = sd;
    } else if (_selectedTime == 'Yesterday') {
      final yest = now.subtract(const Duration(days: 1));
      sd = DateTime(yest.year, yest.month, yest.day).toIso8601String().split('T').first;
      ed = sd;
    } else if (_selectedTime == 'Last 7 Days') {
      final week = now.subtract(const Duration(days: 7));
      sd = DateTime(week.year, week.month, week.day).toIso8601String().split('T').first;
      ed = DateTime(now.year, now.month, now.day).toIso8601String().split('T').first;
    }

    final res = await _apiService.getBanRequests(
      token: token,
      page: _banCurrentPage,
      search: _searchQuery,
      startDate: sd,
      endDate: ed,
    );

    _banRequests = res['items'] ?? [];
    _banCurrentPage = res['currentPage'] ?? 1;
    _banTotalPages = res['totalPages'] ?? 1;

    // Local Type Filtering (Temporary/Permanent)
    if (_selectedType != 'All' && _banRequests.isNotEmpty) {
      _banRequests = _banRequests.where((element) => element.banDuration.toLowerCase() == _selectedType.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty && _banRequests.isNotEmpty) {
      _banRequests = _banRequests.where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Local Date Filtering
    if (sd.isNotEmpty && ed.isNotEmpty && _banRequests.isNotEmpty) {
      try {
        DateTime start = DateTime.parse(sd);
        DateTime end = DateTime.parse(ed);
        _banRequests = _banRequests.where((el) {
          if (el.requestedOn == 'Unknown' || el.requestedOn.isEmpty) return true;
          try {
            DateTime pt = DateTime.parse(el.requestedOn);
            return pt.compareTo(start) >= 0 && pt.compareTo(end) <= 0;
          } catch(e) { return true; }
        }).toList();
      } catch(e) {}
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteWarning(String warningId, String token) async {
    final success = await _apiService.deleteWarning(warningId: warningId, token: token);
    if (success) {
      await fetchWarnings(token);
    }
    return success;
  }

  Future<void> fetchWarnings(String token) async {
    _isLoading = true;
    notifyListeners();

    String sd = _fromDate?.toIso8601String().split('T').first ?? '';
    String ed = _toDate?.toIso8601String().split('T').first ?? '';

    final res = await _apiService.getWarnings(
      token: token,
      page: _warnCurrentPage,
      search: _searchQuery,
      startDate: sd,
      endDate: ed,
    );

    _warnings = res['items'] ?? [];
    _warnCurrentPage = res['currentPage'] ?? 1;
    _warnTotalPages = res['totalPages'] ?? 1;

    if (_searchQuery.isNotEmpty && _warnings.isNotEmpty) {
      _warnings = _warnings.where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  void changePage(int delta, String token) {
    if (_selectedTabIndex == 0) {
      setPage(_banCurrentPage + delta, token);
    } else {
      setPage(_warnCurrentPage + delta, token);
    }
  }

  void setPage(int page, String token) {
    if (_selectedTabIndex == 0) {
      if (page >= 1 && page <= _banTotalPages && page != _banCurrentPage) {
        _banCurrentPage = page;
        fetchBanRequests(token);
      }
    } else {
      if (page >= 1 && page <= _warnTotalPages && page != _warnCurrentPage) {
        _warnCurrentPage = page;
        fetchWarnings(token);
      }
    }
  }

  int get currentPage => _selectedTabIndex == 0 ? _banCurrentPage : _warnCurrentPage;
  int get totalPages => _selectedTabIndex == 0 ? _banTotalPages : _warnTotalPages;
}
