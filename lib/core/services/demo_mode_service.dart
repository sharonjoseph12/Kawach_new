import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawach/app/di/injection.dart';

/// Demo mode for hackathon judges.
/// When active, bypasses real backend calls and shows pre-scripted data
/// so judges can experience every feature without triggering real emergencies.
@LazySingleton()
class DemoModeService extends ChangeNotifier {
  bool _isActive = false;
  
  bool get isActive => _isActive;

  DemoModeService() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = getIt<SharedPreferences>();
      _isActive = prefs.getBool('demo_mode') ?? false;
    } catch (_) {}
  }

  Future<void> toggle() async {
    _isActive = !_isActive;
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setBool('demo_mode', _isActive);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> enable() async {
    _isActive = true;
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setBool('demo_mode', true);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> disable() async {
    _isActive = false;
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setBool('demo_mode', false);
    } catch (_) {}
    notifyListeners();
  }
}
