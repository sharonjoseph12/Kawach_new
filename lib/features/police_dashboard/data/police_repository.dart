import 'package:supabase_flutter/supabase_flutter.dart';

class PoliceRepository {
  final _client = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getActiveAlerts(String stationId) {
    return _client
        .from('police_dashboard_alerts')
        .stream(primaryKey: ['response_id'])
        .eq('station_id', stationId)
        .order('assigned_at');
  }

  Future<void> updateResponseStatus(String responseId, String status) async {
    await _client
        .from('police_responses')
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', responseId);
  }

  Future<Map<String, dynamic>> getAlertDetails(String sosId) async {
    final response = await _client
        .from('sos_alerts')
        .select('*, users_profiles(*)')
        .eq('id', sosId)
        .single();
    return response;
  }
  
  Future<List<Map<String, dynamic>>> getStations() async {
    final response = await _client.from('police_stations').select();
    return List<Map<String, dynamic>>.from(response);
  }
}
