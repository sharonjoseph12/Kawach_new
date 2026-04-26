import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawach/core/database/local_database.dart';
import 'package:kawach/core/database/models/sos_alert_local.dart';
import 'package:kawach/core/error/failures.dart';
import 'package:kawach/features/sos/domain/entities/sos_alert.dart';
import 'package:kawach/features/sos/domain/sos_repository.dart';
import 'package:kawach/features/sos/data/sos_queue_manager.dart';
import 'package:kawach/features/fallback/sms_fallback_service.dart';
import 'package:kawach/features/mesh/nearby_mesh_service.dart';
import 'package:kawach/features/mesh/mesh_message.dart';
import 'package:kawach/features/guardians/data/guardian_repository.dart';
import '../data/sos_remote_datasource.dart';

@LazySingleton(as: SosRepository)
class SosRepositoryImpl implements SosRepository {
  final SosRemoteDataSource _remoteDataSource;
  final LocalDatabase _localDatabase;
  final SosQueueManager _queueManager;
  final SmsFallbackService _smsFallbackService;
  final NearbyMeshService _nearbyMeshService;
  final GuardianRepository _guardianRepository;

  SosRepositoryImpl(
    this._remoteDataSource,
    this._localDatabase,
    this._queueManager,
    this._smsFallbackService,
    this._nearbyMeshService,
    this._guardianRepository,
  );

  @override
  Future<Either<Failure, SosAlert>> triggerSOS({
    required double lat,
    required double lng,
    required int battery,
    required String triggerType,
  }) async {
    debugPrint('KAWACH REPO: triggerSOS called!');
    // 1. Persist Locally First (Offline First)
    final localAlert = SosAlertLocal()
      ..lat = lat
      ..lng = lng
      ..batteryPct = battery
      ..triggerType = triggerType
      ..status = 'triggered'
      ..createdAt = DateTime.now()
      ..remoteId = 'pending_${DateTime.now().millisecondsSinceEpoch}';

    await _localDatabase.saveSosAlert(localAlert);

    // ── ALWAYS SEND SMS FIRST ── (fire-and-forget, don't block on it)
    _sendSmsToGuardians(lat, lng, battery);

    try {
      // 2. Attempt Remote
      final alert = await _remoteDataSource.triggerSOS(
        lat: lat,
        lng: lng,
        battery: battery,
        triggerType: triggerType,
      ).timeout(const Duration(seconds: 4));
      
      // 3. Update local as synced
      localAlert.isSynced = true;
      localAlert.syncedAt = DateTime.now();
      localAlert.remoteId = alert.id;
      await _localDatabase.saveSosAlert(localAlert);
      
      // Trigger Mesh redundantly even if online, to help others
      final prefs = await SharedPreferences.getInstance();
      List<String> phones = [];
      final cached = prefs.getString('cached_guardians_global');
      if (cached != null && cached.isNotEmpty) {
        final List decoded = jsonDecode(cached);
        phones = decoded.map((g) => (g['contact_phone'] ?? '') as String).where((p) => p.isNotEmpty).toList();
      }
      _triggerMesh(localAlert.remoteId, lat, lng, battery, phones.join('|'));

      return Right(alert);
    } catch (e) {
      debugPrint('KAWACH: Remote SOS failed, continuing offline — $e');

      // Trigger Bluetooth Mesh Beacon for Offline-First approach
      final prefs = await SharedPreferences.getInstance();
      List<String> phones = [];
      final cached = prefs.getString('cached_guardians_global');
      if (cached != null && cached.isNotEmpty) {
        final List decoded = jsonDecode(cached);
        phones = decoded.map((g) => (g['contact_phone'] ?? '') as String).where((p) => p.isNotEmpty).toList();
      }
      _triggerMesh(localAlert.remoteId, lat, lng, battery, phones.join('|'));

      // Enqueue for retry when connectivity returns

      // Enqueue for retry when connectivity returns
      try {
        await _queueManager.enqueue(
          lat: lat,
          lng: lng,
          battery: battery,
          triggerType: triggerType,
        );
      } catch (_) {}

      final syntheticAlert = SosAlert(
        id: localAlert.remoteId,
        userId: Supabase.instance.client.auth.currentUser?.id ?? 'offline',
        lat: lat,
        lng: lng,
        batteryPct: battery,
        triggerType: triggerType,
        status: 'triggered',
        origin: 'offline_queued',
        createdAt: DateTime.now(),
      );
      return Right(syntheticAlert);
    }
  }

  @override
  Future<Either<Failure, void>> cancelSOS(String sosId, String reason) async {
    try {
      await _remoteDataSource.cancelSOS(sosId, reason);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<SosAlert?> listenToActiveSOS(String userId) {
    return _remoteDataSource.listenToActiveSOS(userId);
  }

  /// Direct SMS — reads from local cache only, zero network dependency
  Future<void> _sendSmsToGuardians(double lat, double lng, int battery) async {
    try {
      final guardians = await _guardianRepository.fetchGuardians();
      final phones = guardians.map((g) => g.contactPhone).where((p) => p.isNotEmpty).toList();
      
      if (phones.isEmpty) {
        debugPrint('KAWACH SMS: No guardians found, skipping fallback.');
        return;
      }

      await _smsFallbackService.dispatchOfflineDistress(
        lat: lat,
        lng: lng,
        guardianPhones: phones,
      );
    } catch (e) {
      debugPrint('KAWACH SMS: Global fallback failed — $e');
    }
  }

  Future<void> _triggerMesh(String alertId, double lat, double lng, int battery, String phones) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
      bool advertising = await _nearbyMeshService.startAdvertising(MeshMessage(
        msgId: alertId,
        originUserId: currentUserId,
        type: 'SOS',
        timestamp: DateTime.now(),
        payload: 'lat:$lat,lng:$lng,bat:$battery,phones:$phones',
      ));
      debugPrint('KAWACH MESH TRIGGER: Advertising started = $advertising');
    } catch (e) {
      debugPrint('KAWACH MESH TRIGGER: Failed — $e');
    }
  }
}
