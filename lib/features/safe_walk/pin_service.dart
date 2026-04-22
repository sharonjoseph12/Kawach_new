import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PinService {
  static const _pinKey = 'kawach_safe_walk_pin';
  static const _duressPinKey = 'kawach_duress_pin';
  final FlutterSecureStorage _storage;

  PinService() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> savePin(String pin, String duressPin) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _duressPinKey, value: duressPin);
  }

  Future<bool> verifyPin(String input) async {
    final stored = await _storage.read(key: _pinKey);
    return stored == input;
  }

  Future<bool> verifyDuressPin(String input) async {
    final stored = await _storage.read(key: _duressPinKey);
    return stored == input && stored != null;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }
}
