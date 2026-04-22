import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawach/app/di/injection.dart';

@LazySingleton()
class ProfileRepository {
  final _client = Supabase.instance.client;

  String? get userId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>?> fetchProfile() async {
    final uid = userId;
    if (uid == null) return null;
    final res = await _client
        .from('users_profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    return res;
  }

  Future<void> upsertProfile({
    required String fullName,
    String? profileImageUrl,
  }) async {
    final uid = userId;
    if (uid == null) return;
    final phone = _client.auth.currentUser?.phone ?? '';
    await _client.from('users_profiles').upsert({
      'id': uid,
      'full_name': fullName,
      'phone_number': phone,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String> getDisplayName() async {
    final prefs = getIt<SharedPreferences>();
    try {
      final profile = await fetchProfile();
      if (profile != null && (profile['full_name'] as String?)?.isNotEmpty == true) {
        final name = profile['full_name'] as String;
        await prefs.setString('cached_display_name', name);
        return name;
      }
    } catch (_) {}
    
    // Fallback to cache
    final cached = prefs.getString('cached_display_name');
    if (cached != null && cached.isNotEmpty) return cached;

    final phone = _client.auth.currentUser?.phone ?? '';
    if (phone.isNotEmpty) return phone.replaceFirst('+91', '').trim();
    return 'You';
  }
}
