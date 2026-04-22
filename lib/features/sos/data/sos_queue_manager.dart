import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists failed SOS triggers and retries them when connectivity returns.
@lazySingleton
class SosQueueManager {
  static const _queueKey = 'kawach_sos_offline_queue';
  final SupabaseClient _supabase;
  StreamSubscription? _connectivitySub;

  SosQueueManager(this._supabase) {
    _startConnectivityListener();
  }

  /// Listens for network restore and auto-flushes any queued alerts.
  void _startConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) flushQueue();
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  Future<void> enqueue({
    required double lat,
    required double lng,
    required int battery,
    required String triggerType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_queueKey) ?? [];
    existing.add(jsonEncode({
      'latitude': lat,
      'longitude': lng,
      'battery_pct': battery,
      'trigger_type': triggerType,
      'status': 'triggered',
      'queued_at': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(_queueKey, existing);
  }

  /// Called automatically on connectivity restore. Inserts queued alerts into sos_alerts.
  Future<void> flushQueue() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    if (queue.isEmpty) return;

    final remaining = <String>[];
    for (final entry in queue) {
      try {
        final Map<String, dynamic> data = jsonDecode(entry);
        await _supabase.from('sos_alerts').insert({
          'user_id': uid,
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'battery_pct': data['battery_pct'],
          'trigger_type': data['trigger_type'],
          'status': 'triggered',
          'origin': 'offline_queued',
        });
        // success — don't add back to queue
      } catch (_) {
        remaining.add(entry); // keep failed ones for next retry
      }
    }

    await prefs.setStringList(_queueKey, remaining);
  }

  Future<int> queueLength() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_queueKey) ?? []).length;
  }
}
