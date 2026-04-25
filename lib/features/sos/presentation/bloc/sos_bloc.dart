import 'dart:async';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/sos_repository.dart';
import '../../domain/entities/sos_alert.dart';
import 'package:kawach/features/evidence/evidence_upload_service.dart';
import 'package:kawach/features/evidence/data/evidence_audio_pipeline.dart';
import 'package:kawach/features/fallback/sms_fallback_service.dart';
import 'sos_event.dart';
import 'sos_state.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:kawach/features/guardians/data/guardian_repository.dart';

@injectable
class SosBloc extends HydratedBloc<SosEvent, SosState> {
  static const _pinningChannel = MethodChannel('kawach/screen_pinning');
  
  final SosRepository _repository;
  final EvidenceUploadService _evidenceUploadService;
  final SmsFallbackService _smsFallbackService;
  final GuardianRepository _guardianRepository;
  final Battery _battery = Battery();
  StreamSubscription? _locationSubscription;
  StreamSubscription? _activeSosSubscription;

  SosBloc(this._repository, this._evidenceUploadService, this._smsFallbackService, this._guardianRepository) : super(SosInitial()) {
    on<SosTriggerPressed>((event, emit) async {
      emit(SosTriggering());
      
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 6), onTimeout: () async {
          // Fallback: use last known position if GPS is slow
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) return last;
          // Absolute fallback: get any position quickly
          return Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
          );
        });
        final batteryLevel = await _battery.batteryLevel;
        
        final result = await _repository.triggerSOS(
          lat: position.latitude,
          lng: position.longitude,
          battery: batteryLevel,
          triggerType: event.triggerType,
        );

        result.fold(
          (failure) async {
            // Offline fallback -> Fetch real guardian phones then dispatch SMS
            final phones = await _fetchGuardianPhones();
            _smsFallbackService.dispatchOfflineDistress(
              lat: position.latitude,
              lng: position.longitude,
              guardianPhones: phones,
            );
            emit(SosError(failure.message));
          },
          (alert) {
            emit(SosActive(
              alert: alert,
              currentLat: alert.lat,
              currentLng: alert.lng,
            ));
            _pinningChannel.invokeMethod('pinScreen');
            WakelockPlus.enable();
            _startTracking();
            // Auto-capture evidence burst in background
            _evidenceUploadService.captureAndUploadBurst(sosAlertId: alert.id);
            EvidenceAudioPipeline().startContinuousRecording(alert.id);
          },
        );
      } catch (e) {
        emit(SosError(e.toString()));
      }
    });

    on<SosLocationUpdated>((event, emit) {
      if (state is SosActive) {
        final currentState = state as SosActive;
        emit(SosActive(
          alert: currentState.alert,
          currentLat: event.lat,
          currentLng: event.lng,
          evidenceCount: currentState.evidenceCount,
        ));
      }
    });

    on<SosCancelPressed>((event, emit) async {
      if (state is SosActive) {
        final alertId = (state as SosActive).alert.id;
        emit(SosCancelling());
        try {
          await _repository.cancelSOS(alertId, event.reason).timeout(
            const Duration(seconds: 5),
          );
        } catch (_) {
          // Offline or timeout — still resolve locally
        }
        _pinningChannel.invokeMethod('unpinScreen');
        WakelockPlus.disable();
        _stopTracking();
        EvidenceAudioPipeline().stopContinuousRecording();
        emit(SosResolved());
      }
    });

    on<SosEvidenceCaptureDone>((event, emit) {
      if (state is SosActive) {
        final currentState = state as SosActive;
        emit(SosActive(
          alert: currentState.alert,
          currentLat: currentState.currentLat,
          currentLng: currentState.currentLng,
          evidenceCount: currentState.evidenceCount + 1,
        ));
      }
    });
  }

  /// Fetches real guardian phone numbers using the repository (supports local cache).
  Future<List<String>> _fetchGuardianPhones() async {
    try {
      final guardians = await _guardianRepository.fetchGuardians();
      return guardians.map((g) => g.contactPhone).where((p) => p.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  void _startTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      add(SosLocationUpdated(position.latitude, position.longitude));
    });
  }

  void _stopTracking() {
    _locationSubscription?.cancel();
    _activeSosSubscription?.cancel();
  }

  @override
  Future<void> close() {
    WakelockPlus.disable();
    _stopTracking();
    return super.close();
  }

  @override
  SosState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['status'] == 'triggered') {
        EvidenceAudioPipeline().startContinuousRecording(json['id']);
        _startTracking();
        return SosActive(
          alert: SosAlert.fromJson(json),
          currentLat: (json['latitude'] as num?)?.toDouble() ?? 0.0,
          currentLng: (json['longitude'] as num?)?.toDouble() ?? 0.0,
          evidenceCount: json['evidenceCount'] as int? ?? 0,
        );
      }
    } catch (_) {}
    return SosInitial();
  }

  @override
  Map<String, dynamic>? toJson(SosState state) {
    if (state is SosActive) {
      final json = state.alert.toJson();
      json['status'] = 'triggered';
      json['evidenceCount'] = state.evidenceCount;
      return json;
    } else if (state is SosInitial || state is SosResolved) {
      return {'status': 'resolved'};
    }
    return null;
  }
}
