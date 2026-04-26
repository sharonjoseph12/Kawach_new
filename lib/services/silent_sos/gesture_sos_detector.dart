import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GestureSosDetector {
  final VoidCallback onTrigger;
  StreamSubscription? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  static const double _shakeThreshold = 25.0;
  static const int _shakeDurationMs = 300;

  GestureSosDetector({required this.onTrigger});

  void start() async {
    final prefs = await SharedPreferences.getInstance();
    final sensitivity = prefs.getInt('shake_sensitivity') ?? 3;
    
    // Map 1-5 to 40.0-15.0 threshold (magnitude is squared)
    double threshold;
    switch (sensitivity) {
      case 1: threshold = 40.0; break;
      case 2: threshold = 32.0; break;
      case 3: threshold = 25.0; break;
      case 4: threshold = 20.0; break;
      case 5: threshold = 15.0; break;
      default: threshold = 25.0;
    }
    final thresholdSq = threshold * threshold;

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final double magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > thresholdSq) {
        if (_lastShakeTime == null) {
          _lastShakeTime = DateTime.now();
        } else {
          final difference = DateTime.now().difference(_lastShakeTime!).inMilliseconds;
          if (difference >= _shakeDurationMs) {
            onTrigger();
            _lastShakeTime = null; // Reset
          }
        }
      } else {
        _lastShakeTime = null;
      }
    });
  }

  void stop() {
    _accelerometerSubscription?.cancel();
  }
}

class GestureOverlayWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onTrigger;

  const GestureOverlayWrapper({super.key, required this.child, required this.onTrigger});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTertiaryTapUp: (_) => onTrigger(), // 3-finger tap simulation
      child: child,
    );
  }
}
