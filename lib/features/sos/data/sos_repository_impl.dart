import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    try {
      // 2. Attempt Remote
      final alert = await _remoteDataSource.triggerSOS(
        lat: lat,
        lng: lng,
        battery: battery,
        triggerType: triggerType,
      );
      
      // 3. Update local as synced
      localAlert.isSynced = true;
      localAlert.syncedAt = DateTime.now();
      localAlert.remoteId = alert.id;
      await _localDatabase.saveSosAlert(localAlert);
      
      return Right(alert);
    } catch (e) {
      // Trigger Zero-Connectivity SMS Fallback with real guardian phones
      List<String> guardianPhones = [];
      try {
        final guardians = await _guardianRepository.fetchGuardians();
        guardianPhones = guardians.map((g) => g.contactPhone).where((p) => p.isNotEmpty).toList();
      } catch (_) {}

      await _smsFallbackService.dispatchOfflineDistress(
        lat: lat,
        lng: lng,
        guardianPhones: guardianPhones,
      );

      // Trigger Bluetooth Mesh Beacon with real user ID
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
      await _nearbyMeshService.startAdvertising(MeshMessage(
        msgId: localAlert.remoteId,
        originUserId: currentUserId,
        type: 'SOS',
        timestamp: DateTime.now(),
        payload: 'lat:$lat,lng:$lng,bat:$battery',
      ));

      // Enqueue for retry when connectivity returns
      await _queueManager.enqueue(
        lat: lat,
        lng: lng,
        battery: battery,
        triggerType: triggerType,
      );
      // For safety, local success is enough to proceed to active UI
      // Return a synthetic alert so user sees the SOS Active page
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
}
