import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'package:vibration/vibration.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:kawach/features/sos/domain/sos_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';

@LazySingleton()
class HardwareButtonInterceptor {
  int _clickCount = 0;
  Timer? _decayTimer;
  bool _initialized = false;
  static const int _clickThreshold = 3;
  static const Duration _decayDuration = Duration(seconds: 3);
  final _audioPlayer = AudioPlayer();

  void initialize() {
    if (_initialized) return; // Prevent duplicate listeners
    _initialized = true;

    // Hide the volume UI so the attacker doesn't see the volume changing
    PerfectVolumeControl.hideUI = true;

    PerfectVolumeControl.stream.listen((volume) {
      _handleVolumeClick();
    });
    
    // HACK: Play a completely silent minimal WAV file in a loop.
    // This tricks Android into thinking media is actively playing,
    // which prevents the OS from suppressing VOLUME_CHANGED_ACTION 
    // broadcasts when the screen is locked or off.
    _startSilentLoop();

    getIt<Talker>().info('KAWACH: Hardware Volume Button Interceptor ready');
  }

  Future<void> _startSilentLoop() async {
    try {
      // Minimal 44-byte WAV header (no actual audio data, completely silent)
      final silentWav = Uint8List.fromList([
        82, 73, 70, 70, 36, 0, 0, 0, 87, 65, 86, 69, 102, 109, 116, 32, 
        16, 0, 0, 0, 1, 0, 1, 0, 68, 172, 0, 0, 136, 88, 1, 0, 2, 0, 
        16, 0, 100, 97, 116, 97, 0, 0, 0, 0
      ]);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(BytesSource(silentWav));
    } catch (_) {}
  }

  void _handleVolumeClick() {
    _clickCount++;
    getIt<Talker>().info('Volume Button Clicked. Count: $_clickCount');

    _decayTimer?.cancel();
    _decayTimer = Timer(_decayDuration, () {
      _clickCount = 0;
    });

    if (_clickCount >= _clickThreshold) {
      _triggerSos();
      _clickCount = 0;
    }
  }

  Future<void> _triggerSos() async {
    getIt<Talker>().critical('Hardware SOS Triggered via Volume Buttons!');
    
    // Vibrate phone to acknowledge successful trigger to the user
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 1000]);
    }

    try {
      // Fetch real GPS and battery instead of dummy values
      double lat = 0.0, lng = 0.0;
      int battery = 50;
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {}
      try {
        battery = await Battery().batteryLevel;
      } catch (_) {}

      final sosRepo = getIt<SosRepository>();
      await sosRepo.triggerSOS(
        lat: lat, 
        lng: lng, 
        battery: battery, 
        triggerType: 'hardware_volume_button',
      );
    } catch (e) {
      getIt<Talker>().error('Failed to trigger SOS from hardware buttons', e);
    }
  }
}

