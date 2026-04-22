import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/material.dart';

class GestureSosDetector {
  final VoidCallback onTrigger;
  StreamSubscription? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  static const double _shakeThreshold = 25.0;
  static const int _shakeDurationMs = 300;

  GestureSosDetector({required this.onTrigger});

  void start() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final double magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > _shakeThreshold * _shakeThreshold) {
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
