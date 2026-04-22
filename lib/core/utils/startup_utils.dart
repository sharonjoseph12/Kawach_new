import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Call once after successful OTP verification to ensure
/// the user has a profile row. Safe to call multiple times (upsert).
Future<void> ensureProfileExists() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  try {
    await Supabase.instance.client.from('users_profiles').upsert({
      'id': user.id,
      'phone_number': user.phone ?? '',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  } catch (_) {
    // Non-fatal — profile may already exist with more data
  }
}

/// Returns true if internet is available.
Future<bool> hasConnectivity() async {
  try {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none) && result.isNotEmpty;
  } catch (_) {
    return false;
  }
}
