import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/sos_alert.dart';

abstract class SosRemoteDataSource {
  Future<SosAlert> triggerSOS({
    required double lat,
    required double lng,
    required int battery,
    required String triggerType,
  });
  Future<void> cancelSOS(String sosId, String reason);
  Stream<SosAlert?> listenToActiveSOS(String userId);
}

@LazySingleton(as: SosRemoteDataSource)
class SosRemoteDataSourceImpl implements SosRemoteDataSource {
  final SupabaseClient _supabase;

  SosRemoteDataSourceImpl(this._supabase);

  @override
  Future<SosAlert> triggerSOS({
    required double lat,
    required double lng,
    required int battery,
    required String triggerType,
  }) async {
    final uid = _supabase.auth.currentUser!.id;
    final response = await _supabase.from('sos_alerts').insert({
      'user_id': uid,
      'latitude': lat,
      'longitude': lng,
      'trigger_type': triggerType,
      'battery_pct': battery,
      'status': 'triggered',
    }).select().single();

    // Log initial GPS evidence record
    try {
      await _supabase.from('evidence_items').insert({
        'sos_id': response['id'],
        'user_id': uid,
        'type': 'location',
        'file_name': 'gps_${DateTime.now().millisecondsSinceEpoch}.json',
        'file_size_bytes': 0,
        'storage_path': 'gps/$uid/${response['id']}/initial.json',
        'encrypted_hash': DateTime.now().millisecondsSinceEpoch.toRadixString(16),
        'captured_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    return SosAlert.fromJson(response);
  }

  @override
  Future<void> cancelSOS(String sosId, String reason) async {
    await _supabase.from('sos_alerts').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
      'cancel_reason': reason,
    }).eq('id', sosId);
  }

  @override
  Stream<SosAlert?> listenToActiveSOS(String userId) {
    return _supabase
        .from('sos_alerts')
        .stream(primaryKey: ['id'])
        .map((events) => events
            .where((e) => e['user_id'] == userId && e['status'] == 'active')
            .toList())
        .map((events) => events.isEmpty ? null : SosAlert.fromJson(events.first));
  }
}
