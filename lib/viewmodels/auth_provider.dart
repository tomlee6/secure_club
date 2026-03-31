import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/login_service.dart';

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LoginService _loginService = LoginService();

  UserModel? _user;
  String? _accessToken;
  bool _isLoading = false;
  bool _isInit = true;

  UserModel? get user => _user;
  String? get token => _accessToken;
  bool get isLoading => _isLoading;
  bool get isInit => _isInit;
  bool get isAuthenticated => _accessToken != null;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    _isInit = true;
    notifyListeners();

    _accessToken = await _storage.read(key: 'access_token');
    final userJson = await _storage.read(key: 'user');
    
    if (userJson != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        _user = null;
      }
    }

    _isInit = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password, String deviceUuid) async {
    _isLoading = true;
    notifyListeners();

    final result = await _loginService.login(email, password, deviceUuid);

    if (result['success'] == true) {
      _accessToken = result['access_token'];
      _user = result['user'];

      await _storage.write(key: 'access_token', value: _accessToken);
      await _storage.write(key: 'refresh_token', value: result['refresh_token']);
      await _storage.write(key: 'expires_in', value: result['expires_in']?.toString());
      await _storage.write(key: 'user', value: jsonEncode(_user!.toJson()));
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    if (_accessToken != null) {
      await _loginService.logout(_accessToken!);
    }

    _accessToken = null;
    _user = null;
    await _storage.deleteAll();

    _isLoading = false;
    notifyListeners();
  }
}

