import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:vibration/vibration.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:kawach/app/di/injection.dart';

@LazySingleton()
class SirenService {
  Timer? _sirenTimer;
  bool _isActive = false;
  
  bool get isActive => _isActive;

  Future<void> startSiren() async {
    if (_isActive) return;
    _isActive = true;
    
    getIt<Talker>().warning('HIGH-DECIBEL SIREN ACTIVATED');
    
    // In production, we would use AudioPlayer to play a massive 120dB siren asset.
    // For this prototype, we'll simulate the physical stress via intense device vibration patterns
    // combined with the UI flashing red (handled by bloc/ui listener).
    
    if (await Vibration.hasVibrator()) {
      // Very aggressive SOS pattern
      Vibration.vibrate(
        pattern: [0, 500, 100, 500, 100, 500, 300, 800, 100, 800, 100, 800],
        intensities: [255, 255, 255, 255, 255, 255], // Max intensity if supported
        repeat: 1, // Loop the pattern
      );
    }
  }

  Future<void> stopSiren() async {
    if (!_isActive) return;
    _isActive = false;
    
    getIt<Talker>().info('Siren deactivated');
    _sirenTimer?.cancel();
    Vibration.cancel();
  }
}

