import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:injectable/injectable.dart';

class GuardianModel {
  final String id;
  final String contactName;
  final String contactPhone;
  final bool verified;
  final bool isAppUser;

  GuardianModel({
    required this.id,
    required this.contactName,
    required this.contactPhone,
    this.verified = false,
    this.isAppUser = false,
  });

  factory GuardianModel.fromJson(Map<String, dynamic> json) => GuardianModel(
        id: json['id'] as String,
        contactName: json['contact_name'] as String? ?? '',
        contactPhone: json['contact_phone'] as String? ?? '',
        verified: json['verified'] as bool? ?? false,
        isAppUser: json['is_app_user'] as bool? ?? false,
      );
}

@LazySingleton()
class GuardianRepository {
  final _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<GuardianModel>> fetchGuardians() async {
    final uid = _userId;
    if (uid == null) return [];
    final res = await _client
        .from('guardians')
        .select()
        .eq('user_id', uid)
        .order('added_at');
    return (res as List).map((e) => GuardianModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GuardianModel> addGuardian({
    required String name,
    required String phone,
  }) async {
    final uid = _userId!;
    final res = await _client.from('guardians').insert({
      'user_id': uid,
      'contact_name': name,
      'contact_phone': phone,
      'verified': false,
      'is_app_user': false,
    }).select().single();
    return GuardianModel.fromJson(res);
  }

  Future<void> deleteGuardian(String id) async {
    await _client.from('guardians').delete().eq('id', id);
  }
}
