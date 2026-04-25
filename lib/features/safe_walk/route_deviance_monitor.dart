import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:kawach/features/safe_walk/route_deviance_service.dart';
import 'package:kawach/features/sos/domain/sos_repository.dart';

/// Actively monitors GPS and triggers SOS when route deviation is detected.
@LazySingleton()
class RouteDevianceMonitor {
  final RouteDevianceService _devianceService;
  StreamSubscription<Position>? _positionSub;
  Timer? _countdownTimer;
  bool _isMonitoring = false;
  bool _deviationDetected = false;
  int _countdownSeconds = 30;

  // Callback for UI to show warning
  void Function(int secondsRemaining)? onCountdownTick;
  void Function()? onDeviationDetected;
  void Function()? onSosTriggered;

  RouteDevianceMonitor(this._devianceService);

  bool get isMonitoring => _isMonitoring;
  bool get deviationDetected => _deviationDetected;

  Future<void> startMonitoring(LatLng origin, LatLng destination) async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _deviationDetected = false;

    await _devianceService.startTrackingCommute(origin, destination);

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30, // Check every 30 meters
      ),
    ).listen((position) {
      final currentLocation = LatLng(position.latitude, position.longitude);
      final isDeviating = _devianceService.isDeviating(currentLocation);

      if (isDeviating && !_deviationDetected) {
        _deviationDetected = true;
        getIt<Talker>().warning('RouteDevianceMonitor: DEVIATION DETECTED! Starting 30s countdown.');
        onDeviationDetected?.call();

        // Vibrate to warn user
        Vibration.vibrate(pattern: [0, 300, 200, 300, 200, 300]);

        // Start countdown — if user doesn't dismiss, SOS fires
        _countdownSeconds = 30;
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _countdownSeconds--;
          onCountdownTick?.call(_countdownSeconds);

          if (_countdownSeconds <= 0) {
            timer.cancel();
            _triggerSos(position.latitude, position.longitude);
          }
        });
      }
    });

    getIt<Talker>().info('RouteDevianceMonitor: Started monitoring commute.');
  }

  void dismissDeviation() {
    _countdownTimer?.cancel();
    _deviationDetected = false;
    _countdownSeconds = 30;
    getIt<Talker>().info('RouteDevianceMonitor: User dismissed deviation warning.');
  }

  Future<void> _triggerSos(double lat, double lng) async {
    getIt<Talker>().critical('RouteDevianceMonitor: SOS TRIGGERED due to route deviation!');
    onSosTriggered?.call();

    try {
      int battery = 50;
      try { battery = await Battery().batteryLevel; } catch (_) {}
      final sosRepo = getIt<SosRepository>();
      await sosRepo.triggerSOS(
        lat: lat,
        lng: lng,
        battery: battery,
        triggerType: 'route_deviance',
      );
    } catch (e) {
      getIt<Talker>().error('RouteDevianceMonitor: Failed to trigger SOS', e);
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _deviationDetected = false;
    _positionSub?.cancel();
    _countdownTimer?.cancel();
    _devianceService.stopTracking();
    getIt<Talker>().info('RouteDevianceMonitor: Stopped monitoring.');
  }
}
