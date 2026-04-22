import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  static const double _threshold = 22.0; // m/s²
  static const int _sustainedMs = 400;
  static const int _debounceMs = 5000;

  final void Function() onShakeDetected;
  StreamSubscription<AccelerometerEvent>? _subscription;

  DateTime? _thresholdHitAt;
  DateTime? _lastTrigger;
  bool _active = false;

  ShakeDetector({required this.onShakeDetected});

  void start() {
    if (_active) return;
    _active = true;
    _subscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(_onEvent);
  }

  void stop() {
    _active = false;
    _thresholdHitAt = null;
    _subscription?.cancel();
    _subscription = null;
  }

  void _onEvent(AccelerometerEvent e) {
    // Remove gravity (9.8 m/s²) — approximate net acceleration
    final magnitude =
        sqrt(e.x * e.x + e.y * e.y + e.z * e.z) - 9.8;

    final now = DateTime.now();

    if (magnitude > _threshold) {
      _thresholdHitAt ??= now;
      final sustained = now.difference(_thresholdHitAt!).inMilliseconds;
      if (sustained >= _sustainedMs) {
        // Debounce
        if (_lastTrigger == null ||
            now.difference(_lastTrigger!).inMilliseconds > _debounceMs) {
          _lastTrigger = now;
          _thresholdHitAt = null;
          HapticFeedback.heavyImpact();
          onShakeDetected();
        }
      }
    } else {
      _thresholdHitAt = null;
    }
  }
}
