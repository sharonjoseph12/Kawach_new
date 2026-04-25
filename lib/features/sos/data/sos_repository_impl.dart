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
      );
      
      // 3. Update local as synced
      localAlert.isSynced = true;
      localAlert.syncedAt = DateTime.now();
      localAlert.remoteId = alert.id;
      await _localDatabase.saveSosAlert(localAlert);
      
      return Right(alert);
    } catch (e) {
      debugPrint('KAWACH: Remote SOS failed, continuing offline — $e');

      // Trigger Bluetooth Mesh Beacon with real user ID
      try {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
        await _nearbyMeshService.startAdvertising(MeshMessage(
          msgId: localAlert.remoteId,
          originUserId: currentUserId,
          type: 'SOS',
          timestamp: DateTime.now(),
          payload: 'lat:$lat,lng:$lng,bat:$battery',
        ));
      } catch (_) {}

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
      debugPrint('KAWACH SMS: Starting direct SMS send...');
      
      // Read guardian phones DIRECTLY from SharedPreferences cache
      // This avoids any Supabase call that could hang when offline
      final prefs = await SharedPreferences.getInstance();
      List<String> phones = [];
      
      // Try global cache first (most reliable)
      final cached = prefs.getString('cached_guardians_global');
      if (cached != null && cached.isNotEmpty) {
        final List decoded = jsonDecode(cached);
        phones = decoded
            .map((g) => (g['contact_phone'] ?? '') as String)
            .where((p) => p.isNotEmpty)
            .toList();
      }
      
      debugPrint('KAWACH SMS: Found ${phones.length} cached guardian phones');
      
      if (phones.isEmpty) {
        debugPrint('KAWACH SMS: No cached guardians — cannot send');
        return;
      }

      // Request permission
      final permStatus = await Permission.sms.request();
      debugPrint('KAWACH SMS: Permission status = $permStatus');
      if (!permStatus.isGranted) {
        debugPrint('KAWACH SMS: Permission denied');
        return;
      }

      final telephony = Telephony.instance;
      final message = "KAWACH SOS! I need help! "
          "Location: https://maps.google.com/?q=$lat,$lng "
          "Battery: $battery%";

      for (final phone in phones) {
        try {
          debugPrint('KAWACH SMS: Sending to $phone...');
          await telephony.sendSms(to: phone, message: message);
          debugPrint('KAWACH SMS: ✅ Sent to $phone');
        } catch (e) {
          debugPrint('KAWACH SMS: ❌ Failed for $phone — $e');
        }
      }
    } catch (e) {
      debugPrint('KAWACH SMS: Fatal error — $e');
    }
  }
}
