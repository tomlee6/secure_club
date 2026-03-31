import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _autoFlashEnabled = true;
  bool get autoFlashEnabled => _autoFlashEnabled;

  void toggleAutoFlash(bool value) {
    _autoFlashEnabled = value;
    notifyListeners();
  }
}
