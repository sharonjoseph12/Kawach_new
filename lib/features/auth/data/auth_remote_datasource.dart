import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:injectable/injectable.dart';

abstract class AuthRemoteDataSource {
  Future<void> sendOTP(String phone);
  Future<void> verifyOTP(String phone, String otp);
  Future<void> signOut();
  bool isAuthenticated();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSourceImpl(this._supabase);

  @override
  Future<void> sendOTP(String phone) async {
    await _supabase.auth.signInWithOtp(
      phone: phone,
      shouldCreateUser: true,
    );
  }

  @override
  Future<void> verifyOTP(String phone, String otp) async {
    await _supabase.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }
}
