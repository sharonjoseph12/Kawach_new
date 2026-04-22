import 'dart:async';

import 'package:record/record.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Replaces the broken tflite stub with a rule-based audio threat detector
/// using amplitude monitoring from the microphone stream.
/// 
/// This approach works without any model files and is hackathon-demo ready.
class AudioThreatService {
  final Talker _log;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSubscription;
  bool _isMonitoring = false;

  // Consecutive high-amplitude readings needed to fire alert
  int _consecutiveHits = 0;
  static const int _hitsRequired = 3;

  // Amplitude threshold: -10 dB is very loud (shouting/screaming range)
  static const double _dbThreshold = -10.0;

  AudioThreatService(this._log);

  Future<void> initialize() async {
    // No model loading needed
    _log.info('AudioThreatService ready (amplitude-based)');
  }

  Future<void> startMonitoring({
    required void Function(String threatType) onThreatDetected,
  }) async {
    if (_isMonitoring) return;

    if (!await _recorder.hasPermission()) {
      _log.warning('AudioThreatService: microphone permission denied');
      return;
    }

    _isMonitoring = true;
    _consecutiveHits = 0;

    try {
      // Use amplitude stream — no audio file written
      await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      // Monitor amplitude every 500ms instead of raw PCM
      _ampSubscription = Stream.periodic(const Duration(milliseconds: 500))
          .asyncMap((_) => _recorder.getAmplitude())
          .listen((amp) {
        _analyzeAmplitude(amp.current, onThreatDetected);
      });
    } catch (e) {
      _log.error('AudioThreatService start error', e);
      _isMonitoring = false;
    }
  }

  void _analyzeAmplitude(
      double db, void Function(String) onThreatDetected) {
    if (db > _dbThreshold) {
      _consecutiveHits++;
      if (_consecutiveHits >= _hitsRequired) {
        _consecutiveHits = 0;
        // Classify by intensity
        final type = db > -5.0 ? 'Screaming' : 'Loud disturbance';
        _log.warning('AudioThreatService: threat detected [$type] at ${db.toStringAsFixed(1)} dB');
        onThreatDetected(type);
      }
    } else {
      _consecutiveHits = 0;
    }
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _consecutiveHits = 0;
    await _ampSubscription?.cancel();
    _ampSubscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  void dispose() {
    stopMonitoring();
    _recorder.dispose();
  }
}
