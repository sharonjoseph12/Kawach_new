import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:battery_plus/battery_plus.dart';
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
      debugPrint('KAWACH BLOC: SOS Trigger Received! Type: ${event.triggerType}');
      
      // Start 15-second countdown
      for (int i = 15; i >= 0; i--) {
        emit(SosTriggering(countdown: i));
        await Future.delayed(const Duration(seconds: 1));
        
        // Check if user cancelled during the countdown
        if (state is! SosTriggering) {
          debugPrint('KAWACH BLOC: SOS Trigger Cancelled during countdown');
          return;
        }
      }

      try {
        // ── STEP 1: FAST LOCATION ───────────────────────────────────────────
        debugPrint('KAWACH BLOC: Fetching FAST location...');
        Position? position = await Geolocator.getLastKnownPosition();
        
        // If no last known, do a very quick current position check (max 1s)
        position ??= await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(milliseconds: 1000),
          ).catchError((_) => Position(
            longitude: 77.5946, latitude: 12.9716, // Bangalore fallback
            timestamp: DateTime.now(),
            accuracy: 0.0, altitude: 0.0, altitudeAccuracy: 0.0,
            heading: 0.0, headingAccuracy: 0.0, speed: 0.0, speedAccuracy: 0.0,
          ));

        final batteryLevel = await _battery.batteryLevel;
        final phones = await _fetchGuardianPhones();
        final primaryPhone = phones.isNotEmpty ? phones.first : null;

        // ── STEP 2: INSTANT STATE TRANSITION ───────────────────────────────
        // We emit SosActive with a placeholder alert so the UI opens the dialer IMMEDIATELY
        final placeholderAlert = SosAlert(
          id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'me',
          lat: position.latitude,
          lng: position.longitude,
          status: 'triggered',
          triggerType: event.triggerType,
          createdAt: DateTime.now(),
        );

        emit(SosActive(
          alert: placeholderAlert,
          currentLat: position.latitude,
          currentLng: position.longitude,
          primaryGuardianPhone: primaryPhone,
        ));

        // ── STEP 3: BACKGROUND REPOSITORY CALL ─────────────────────────────
        // We don't await the server call anymore; we let it run in parallel
        unawaited(_repository.triggerSOS(
          lat: position.latitude,
          lng: position.longitude,
          battery: batteryLevel,
          triggerType: event.triggerType,
        ).then((result) {
          result.fold(
            (failure) {
               // If server fails, we've already done native fallback in the background (remote_datasource)
               debugPrint('KAWACH BLOC: Background SOS trigger finished with failure: ${failure.message}');
            },
            (realAlert) {
               // Update state with real alert ID if needed
               debugPrint('KAWACH BLOC: Background SOS trigger succeeded! ID: ${realAlert.id}');
               // We could re-emit SosActive here to update the ID, but UI already has the dialer open
            }
          );
        }));

        // ── STEP 4: NATIVE HARDWARE / APP STATE ────────────────────────────
        _pinningChannel.invokeMethod('pinScreen');
        WakelockPlus.enable();
        _startTracking();
        
        // Capture evidence burst (non-blocking)
        unawaited(_evidenceUploadService.captureAndUploadBurst(sosAlertId: placeholderAlert.id));
        EvidenceAudioPipeline().startContinuousRecording(placeholderAlert.id);

      } catch (e) {
        debugPrint('KAWACH BLOC: SOS Critical Error: $e');
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
          primaryGuardianPhone: currentState.primaryGuardianPhone,
        ));
      }
    });

    on<SosCancelPressed>((event, emit) async {
      if (state is SosTriggering) {
        emit(SosInitial());
        return;
      }

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
          primaryGuardianPhone: currentState.primaryGuardianPhone,
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
          primaryGuardianPhone: json['primaryGuardianPhone'] as String?,
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
      json['primaryGuardianPhone'] = state.primaryGuardianPhone;
      return json;
    } else if (state is SosInitial || state is SosResolved) {
      return {'status': 'resolved'};
    }
    return null;
  }
}
