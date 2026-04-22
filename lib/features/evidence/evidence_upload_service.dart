import 'dart:io';
import 'package:camera/camera.dart';
import 'package:injectable/injectable.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Automatically captures a burst of 3 front-camera photos and uploads
/// them to Supabase Storage evidence bucket on SOS trigger.
@lazySingleton
class EvidenceUploadService {
  final SupabaseClient _supabase;
  CameraController? _controller;

  EvidenceUploadService(this._supabase);

  /// Call this immediately when SOS is triggered.
  Future<List<String>> captureAndUploadBurst({required String sosAlertId}) async {
    final uploadedUrls = <String>[];
    try {
      final cameras = await availableCameras();
      final frontCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(frontCam, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();

      // Burst: 3 photos with 1s interval
      for (int i = 0; i < 3; i++) {
        final xFile = await _controller!.takePicture();
        final url = await _uploadFile(
          file: File(xFile.path),
          sosAlertId: sosAlertId,
          index: i,
        );
        if (url != null) uploadedUrls.add(url);
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (_) {
      // Silently fail — don't interrupt SOS flow
    } finally {
      await _controller?.dispose();
      _controller = null;
    }
    return uploadedUrls;
  }

  Future<String?> _uploadFile({
    required File file,
    required String sosAlertId,
    required int index,
  }) async {
    try {
      final uid = _supabase.auth.currentUser?.id ?? 'anon';
      final fileName = '${sosAlertId}_burst_${index}_${const Uuid().v4()}.jpg';

      // Path must start with uid/ to satisfy storage RLS: foldername[1] = auth.uid()
      final path = '$uid/$sosAlertId/$fileName';

      await _supabase.storage.from('evidence').upload(
        path,
        file,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
      );

      // Store metadata in evidence_items
      try {
        final stat = file.statSync();
        await _supabase.from('evidence_items').insert({
          'sos_id': sosAlertId,
          'user_id': uid,
          'type': 'photo',
          'file_name': fileName,
          'file_size_bytes': stat.size,
          'storage_path': path,
          'encrypted_hash': stat.size.toRadixString(16),
          'captured_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      return _supabase.storage.from('evidence').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }
}
