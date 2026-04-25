import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

/// Live safety score computed from real device sensor data.
/// Score ranges from 0 (extreme danger) to 100 (maximum safety).
class SafetyScore {
  final int score;
  final String riskLevel; // 'safe', 'moderate', 'high'
  final List<SafetyFactor> factors;

  SafetyScore({required this.score, required this.riskLevel, required this.factors});
}

class SafetyFactor {
  final String label;
  final String detail;
  final bool isPositive;

  SafetyFactor({required this.label, required this.detail, required this.isPositive});
}

@LazySingleton()
class SafetyScoreService {
  final _battery = Battery();

  /// Computes a real-time safety score from device sensors and context.
  Future<SafetyScore> computeScore() async {
    int score = 100;
    final factors = <SafetyFactor>[];

    // ── 1. Time of day ────────────────────────────────
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 5) {
      score -= 25;
      factors.add(SafetyFactor(label: 'Late Night', detail: 'Higher risk after 10 PM', isPositive: false));
    } else if (hour >= 18 || hour < 6) {
      score -= 10;
      factors.add(SafetyFactor(label: 'Evening Hours', detail: 'Slightly elevated risk', isPositive: false));
    } else {
      factors.add(SafetyFactor(label: 'Daytime', detail: 'Lower risk during daylight', isPositive: true));
    }

    // ── 2. Battery level ──────────────────────────────
    try {
      final batteryLevel = await _battery.batteryLevel;
      if (batteryLevel < 10) {
        score -= 20;
        factors.add(SafetyFactor(label: 'Critical Battery', detail: '$batteryLevel% — SOS may fail', isPositive: false));
      } else if (batteryLevel < 25) {
        score -= 10;
        factors.add(SafetyFactor(label: 'Low Battery', detail: '$batteryLevel% remaining', isPositive: false));
      } else {
        factors.add(SafetyFactor(label: 'Battery OK', detail: '$batteryLevel% charged', isPositive: true));
      }
    } catch (_) {
      score -= 5;
    }

    // ── 3. Network connectivity ───────────────────────
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasNetwork = connectivity.any((r) => r != ConnectivityResult.none);
      if (!hasNetwork) {
        score -= 20;
        factors.add(SafetyFactor(label: 'Offline', detail: 'No network — SOS uses BLE mesh', isPositive: false));
      } else {
        final isWifi = connectivity.any((r) => r == ConnectivityResult.wifi);
        factors.add(SafetyFactor(label: 'Connected', detail: isWifi ? 'WiFi' : 'Mobile Data', isPositive: true));
      }
    } catch (_) {
      score -= 10;
    }

    // ── 4. GPS availability ───────────────────────────
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        score -= 15;
        factors.add(SafetyFactor(label: 'GPS Disabled', detail: 'Location services off', isPositive: false));
      } else {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always) {
          factors.add(SafetyFactor(label: 'GPS Active', detail: 'Always-on tracking', isPositive: true));
        } else if (permission == LocationPermission.whileInUse) {
          score -= 5;
          factors.add(SafetyFactor(label: 'GPS Limited', detail: 'Only while app is open', isPositive: false));
        } else {
          score -= 15;
          factors.add(SafetyFactor(label: 'GPS Denied', detail: 'No location access', isPositive: false));
        }
      }
    } catch (_) {
      score -= 10;
    }

    // ── 5. Day of week ────────────────────────────────
    final weekday = DateTime.now().weekday;
    if (weekday == DateTime.friday || weekday == DateTime.saturday) {
      score -= 5;
      factors.add(SafetyFactor(label: 'Weekend Night', detail: 'Statistically higher risk', isPositive: false));
    }

    // Clamp and determine risk level
    score = score.clamp(0, 100);
    final riskLevel = score >= 70 ? 'safe' : score >= 40 ? 'moderate' : 'high';

    return SafetyScore(score: score, riskLevel: riskLevel, factors: factors);
  }
}
