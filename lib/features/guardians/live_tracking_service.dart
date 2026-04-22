import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:injectable/injectable.dart';

/// Broadcasts live GPS to Supabase Realtime during an active SOS.
/// Guardians subscribe via the guardian live-tracking web page.
@lazySingleton
class LiveTrackingService {
  final SupabaseClient _supabase;

  LiveTrackingService(this._supabase);

  /// Call every time the location updates during active SOS.
  Future<void> broadcastLocation({
    required String alertId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _supabase.from('sos_live_location').upsert({
        'alert_id': alertId,
        'lat': lat,
        'lng': lng,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'alert_id');
    } catch (_) {
      // Silent — don't disrupt SOS flow
    }
  }

  /// Returns a shareable link for guardians to watch live.
  String buildShareableTrackingUrl(String alertId) {
    return 'https://kawach.app/track/$alertId';
  }
}
