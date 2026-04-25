import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'contact_name': contactName,
    'contact_phone': contactPhone,
    'verified': verified,
    'is_app_user': isAppUser,
  };

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
  static const _cacheKey = 'cached_guardians';
  static const _lastUidKey = 'last_known_uid';

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<GuardianModel>> fetchGuardians() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = _userId;
    
    // If offline and UID is null, try to use last known UID
    if (uid == null) {
      uid = prefs.getString(_lastUidKey);
    } else {
      // Save UID for future offline use
      await prefs.setString(_lastUidKey, uid);
    }

    if (uid == null) {
      debugPrint('KAWACH: No user ID found for guardian fetch');
      return [];
    }
    
    try {
      final res = await _client
          .from('guardians')
          .select()
          .eq('user_id', uid)
          .order('added_at');
      
      final list = (res as List).map((e) => GuardianModel.fromJson(e as Map<String, dynamic>)).toList();
      
      // Cache locally with UID-specific key AND a global fallback key
      final jsonList = list.map((e) => e.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      await prefs.setString('${_cacheKey}_$uid', encoded);
      await prefs.setString('${_cacheKey}_global', encoded); // Global fallback
      
      return list;
    } catch (e) {
      // Return cached if offline
      // 1. Try UID-specific cache
      String? cached = prefs.getString('${_cacheKey}_$uid');
      // 2. Fallback to global cache if UID cache is empty
      cached ??= prefs.getString('${_cacheKey}_global');
      
      if (cached != null) {
        final List decoded = jsonDecode(cached);
        return decoded.map((e) => GuardianModel.fromJson(e)).toList();
      }
      return [];
    }
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
      'verified': true,
      'is_app_user': false,
    }).select().single();
    
    final model = GuardianModel.fromJson(res);
    // Refresh cache
    await fetchGuardians();
    return model;
  }

  Future<void> deleteGuardian(String id) async {
    await _client.from('guardians').delete().eq('id', id);
    // Refresh cache
    await fetchGuardians();
  }
}
