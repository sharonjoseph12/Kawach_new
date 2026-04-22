import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:kawach/core/database/local_database.dart';
import 'package:kawach/core/database/models/sos_alert_local.dart';
import 'package:kawach/core/error/failures.dart';
import 'package:kawach/features/sos/domain/entities/sos_alert.dart';
import 'package:kawach/features/sos/domain/sos_repository.dart';
import 'package:kawach/features/sos/data/sos_queue_manager.dart';
import 'package:kawach/services/fallback/sms_fallback_service.dart';
import 'package:kawach/services/mesh/bluetooth_mesh_service.dart';
import '../data/sos_remote_datasource.dart';

@LazySingleton(as: SosRepository)
class SosRepositoryImpl implements SosRepository {
  final SosRemoteDataSource _remoteDataSource;
  final LocalDatabase _localDatabase;
  final SosQueueManager _queueManager;

  SosRepositoryImpl(this._remoteDataSource, this._localDatabase, this._queueManager);

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
      ..status = 'active'
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
      // Trigger Zero-Connectivity SMS Fallback
      await SmsFallbackService.initiateOfflineSos(
        lat: lat,
        lng: lng,
        battery: battery,
        triggerType: triggerType,
      );

      // Trigger Bluetooth Mesh Beacon
      await BluetoothMeshService.startDistressBeacon(
        lat: lat,
        lng: lng,
      );

      // Enqueue for retry when connectivity returns
      await _queueManager.enqueue(
        lat: lat,
        lng: lng,
        battery: battery,
        triggerType: triggerType,
      );
      // For safety, local success is enough to proceed to active UI
      return const Left(ServerFailure('Offline: Alert saved locally and queued for sync.'));
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
