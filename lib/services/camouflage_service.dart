import 'package:flutter/services.dart';

class CamouflageService {
  static const _channel = MethodChannel('kawach/camouflage');

  /// Enables the disguise. The "Kawach" app icon vanishes from the app drawer, 
  /// and a "Calculator" icon appears in its place.
  static Future<bool> enableCamouflage() async {
    try {
      final result = await _channel.invokeMethod('setCamouflage', {'enable': true});
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Disables the disguise, restoring the original "Kawach" app icon.
  static Future<bool> disableCamouflage() async {
    try {
      final result = await _channel.invokeMethod('setCamouflage', {'enable': false});
      return result == true;
    } catch (e) {
      return false;
    }
  }
}
