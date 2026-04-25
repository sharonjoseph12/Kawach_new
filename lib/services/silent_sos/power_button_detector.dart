import 'package:flutter/services.dart';

/// Listens for power-button triple-press events sent from native Android.
/// Receiving side of the MethodChannel defined in MainActivity.kt.
class PowerButtonDetector {
  static const _channel = EventChannel('com.kawach/hardware_trigger');

  static Stream<void>? _stream;

  /// Emits one event per SOS trigger (3 rapid presses within 2s).
  static Stream<void> get sosTriggered {
    _stream ??= _channel
        .receiveBroadcastStream()
        .map((_) {});
    return _stream!;
  }
}
