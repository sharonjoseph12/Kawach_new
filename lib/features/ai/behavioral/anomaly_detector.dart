import 'dart:convert';
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:kawach/core/config/app_config.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:talker_flutter/talker_flutter.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class LocationPoint {
  final double lat;
  final double lng;
  final double speed; // m/s
  final double accuracy; // metres
  final DateTime timestamp;

  const LocationPoint({
    required this.lat,
    required this.lng,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
  });
}

enum AnomalyType {
  suddenRunning,
  prolongedInactivity,
  routeDeviation,
  kidnap,
  nighttimeRisk,
}

class AnomalyResult {
  final AnomalyType type;
  double confidence;
  final DateTime detectedAt;
  final LocationPoint location;
  bool requiresImmediateSOS;

  AnomalyResult({
    required this.type,
    required this.confidence,
    required this.detectedAt,
    required this.location,
    required this.requiresImmediateSOS,
  });
}

// ── Detector ─────────────────────────────────────────────────────────────────

class AnomalyDetector {
  final List<LocationPoint> _window = [];
  static const int _maxWindow = 20;

  List<LocationPoint> historyLast7Days = [];
  double currentAreaSafetyScore = 100;
  DateTime? lastUserInteraction;

  late final GenerativeModel _aiValidator;
  bool _isAiConfigured = false;

  AnomalyDetector() {
    try {
      final config = getIt<AppConfig>();
      if (config.geminiApiKey.isNotEmpty) {
        _aiValidator = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: config.geminiApiKey,
        );
        _isAiConfigured = true;
      }
    } catch (_) {
      // Configuration empty or not initialized yet
    }
  }

  void addPoint(LocationPoint point) {
    _window.add(point);
    if (_window.length > _maxWindow) _window.removeAt(0);
  }

  Future<AnomalyResult?> detectAnomalies(List<LocationPoint> history) async {
    for (final p in history) {
      addPoint(p);
    }
    if (_window.length < 5) return null;

    final now = DateTime.now();
    final hour = now.hour;

    AnomalyResult? initialResult;

    // ── Check 1: Sudden Running ───────────────────────────────────────────
    if (_window.length >= 3) {
      final last3 = _window.sublist(_window.length - 3);
      final avgSpeed = last3.map((p) => p.speed).reduce((a, b) => a + b) / 3;

      double accel = 0;
      for (int i = 1; i < last3.length; i++) {
        final dt = last3[i].timestamp.difference(last3[i - 1].timestamp).inMilliseconds.clamp(1, 60000) / 1000.0;
        accel = max(accel, (last3[i].speed - last3[i - 1].speed).abs() / dt);
      }

      final isNight = hour >= 20 || hour < 6;
      if (avgSpeed > 3.5 && accel > 2.0 && isNight) {
        initialResult = AnomalyResult(
          type: AnomalyType.suddenRunning,
          confidence: 0.85,
          detectedAt: now,
          location: _window.last,
          requiresImmediateSOS: true,
        );
      }
    }

    // ── Check 4: Kidnap ───────────────────────────────────────────────────
    if (initialResult == null && _window.length >= 6) {
      final currentSpeed = _window.last.speed;
      final fiveMinAgo = now.subtract(const Duration(minutes: 5));
      final recentBefore = _window.where((p) => p.timestamp.isBefore(fiveMinAgo)).toList();

      if (recentBefore.isNotEmpty) {
        final prevAvgSpeed = recentBefore.map((p) => p.speed).reduce((a, b) => a + b) / recentBefore.length;
        final noInteraction = lastUserInteraction == null || now.difference(lastUserInteraction!).inMinutes > 4;

        if (currentSpeed > 12 && prevAvgSpeed < 1.5 && noInteraction) {
          initialResult = AnomalyResult(
            type: AnomalyType.kidnap,
            confidence: 0.90,
            detectedAt: now,
            location: _window.last,
            requiresImmediateSOS: true,
          );
        }
      }
    }

    // ── AI Validation for Marginal Cases ──────────────────────────────────
    if (initialResult != null && initialResult.confidence > 0.60 && initialResult.confidence < 0.95 && _isAiConfigured) {
      initialResult = await _validateWithGemini(initialResult);
    }

    return initialResult;
  }

  Future<AnomalyResult> _validateWithGemini(AnomalyResult result) async {
    try {
      // ignore: prefer_const_declarations
      final prompt = '''
Analyze this kinematic scenario to validate a personal safety threat:
Type: ${result.type.name}
Base Confidence: ${result.confidence}
Speed: ${result.location.speed} m/s
Time: ${result.detectedAt}
Area Safety Score (0-100, lower is worse): $currentAreaSafetyScore

Is this a real emergency? Respond strictly with a JSON object:
{"confirmed": true/false, "adjustedConfidence": 0.0-1.0}
''';
      final aiResponse = await _aiValidator.generateContent([Content.text(prompt)]);
      
      final text = aiResponse.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '{}';
      final json = jsonDecode(text);
      
      if (json['confirmed'] == true) {
        result.confidence = (json['adjustedConfidence'] as num).toDouble();
        if (result.confidence > 0.85) {
          result.requiresImmediateSOS = true;
        }
      } else {
        result.confidence = 0.3; // Downgrade below trigger threshold
        result.requiresImmediateSOS = false;
      }
    } catch (e) {
      getIt<Talker>().warning('Gemini AI Validation failed, fallback to rules', e);
    }
    return result;
  }
}
