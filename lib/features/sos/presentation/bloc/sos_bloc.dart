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

@injectable
class SosBloc extends HydratedBloc<SosEvent, SosState> {
  static const _pinningChannel = MethodChannel('kawach/screen_pinning');
  
  final SosRepository _repository;
  final EvidenceUploadService _evidenceUploadService;
  final Battery _battery = Battery();
  StreamSubscription? _locationSubscription;
  StreamSubscription? _activeSosSubscription;

  SosBloc(this._repository, this._evidenceUploadService) : super(SosInitial()) {
    on<SosTriggerPressed>((event, emit) async {
      emit(SosTriggering());
      
      try {
        final position = await Geolocator.getCurrentPosition();
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
            SmsFallbackService().dispatchOfflineDistress(
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
        final result = await _repository.cancelSOS(alertId, event.reason);
        result.fold(
          (failure) => emit(SosError(failure.message)),
          (_) {
            _pinningChannel.invokeMethod('unpinScreen');
            WakelockPlus.disable();
            _stopTracking();
            EvidenceAudioPipeline().stopContinuousRecording();
            emit(SosResolved());
          },
        );
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

  /// Fetches real guardian phone numbers from Supabase for offline SMS fallback.
  Future<List<String>> _fetchGuardianPhones() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return [];
      final res = await Supabase.instance.client
          .from('guardians')
          .select('contact_phone')
          .eq('user_id', uid)
          .not('contact_phone', 'is', null);
      return (res as List)
          .map((g) => g['contact_phone'] as String)
          .where((p) => p.isNotEmpty)
          .toList();
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
      if (json['status'] == 'active') {
        EvidenceAudioPipeline().startContinuousRecording(json['id']);
        _startTracking();
        return SosActive(
          alert: SosAlert.fromJson(json),
          currentLat: json['lat'],
          currentLng: json['lng'],
          evidenceCount: json['evidenceCount'] ?? 0,
        );
      }
    } catch (_) {}
    return SosInitial();
  }

  @override
  Map<String, dynamic>? toJson(SosState state) {
    if (state is SosActive) {
      final json = state.alert.toJson();
      json['status'] = 'active';
      json['evidenceCount'] = state.evidenceCount;
      return json;
    } else if (state is SosInitial || state is SosResolved) {
      return {'status': 'resolved'};
    }
    return null;
  }
}
