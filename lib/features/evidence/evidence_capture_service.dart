import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:injectable/injectable.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:kawach/app/di/injection.dart';
import '../../core/security/encryption_service.dart';

@LazySingleton()
class EvidenceCaptureService {
  final SupabaseClient _supabase;
  final EncryptionService _encryptionService;
  final _audioRecorder = AudioRecorder();

  EvidenceCaptureService(this._supabase, this._encryptionService);

  Future<void> captureAll(String sosId) async {
    getIt<Talker>().info('EvidenceCaptureService: Starting overt/covert capture for SOS $sosId');
    // Using Future.wait to capture simultaneously
    await Future.wait([
      _captureAudio(sosId),
      _capturePhoto(sosId),
      _captureGPSLog(sosId),
      _captureSensorLog(sosId),
    ]);
    getIt<Talker>().info('EvidenceCaptureService: Finished capture cycle');
  }

  Future<void> _captureAudio(String sosId) async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final path = '${(await getTemporaryDirectory()).path}/audio_$sosId.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        await Future.delayed(const Duration(seconds: 15)); // Capture 15s chunks
        final finalPath = await _audioRecorder.stop();
        
        if (finalPath != null) {
          await _processAndUpload(sosId, File(finalPath), 'audio');
        }
      }
    } catch (e) {
      getIt<Talker>().error('EvidenceCaptureService: Audio capture failed', e);
    }
  }

  Future<void> _capturePhoto(String sosId) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      final controller = CameraController(
        frontCamera, 
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await controller.initialize();
      // Disable flash and shutter sound for covertness if possible (depends on OS)
      await controller.setFlashMode(FlashMode.off);
      
      final photo = await controller.takePicture();
      await controller.dispose();
      
      await _processAndUpload(sosId, File(photo.path), 'photo');
    } catch (e) {
      getIt<Talker>().error('EvidenceCaptureService: Photo capture failed', e);
    }
  }

  Future<void> _captureGPSLog(String sosId) async {
    try {
      final logs = <Map<String, dynamic>>[];
      for (int i = 0; i < 4; i++) { // 20 seconds, every 5s
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        logs.add({
          'lat': pos.latitude,
          'lng': pos.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });
        await Future.delayed(const Duration(seconds: 5));
      }
      
      final bytes = utf8.encode(jsonEncode(logs));
      await _uploadBytes(sosId, Uint8List.fromList(bytes), 'gps_log', 'json');
    } catch (e) {
      getIt<Talker>().error('EvidenceCaptureService: GPS log capture failed', e);
    }
  }

  Future<void> _captureSensorLog(String sosId) async {
    try {
      final logs = <Map<String, dynamic>>[];
      final subscription = accelerometerEventStream().listen((event) {
        // Sample every few events to avoid massive JSON
        if (logs.length < 100) {
          logs.add({
            'x': event.x,
            'y': event.y,
            'z': event.z,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      });
      
      await Future.delayed(const Duration(seconds: 15));
      await subscription.cancel();
      
      final bytes = utf8.encode(jsonEncode(logs));
      await _uploadBytes(sosId, Uint8List.fromList(bytes), 'sensor_log', 'json');
    } catch (e) {
      getIt<Talker>().error('EvidenceCaptureService: Sensor log capture failed', e);
    }
  }

  Future<void> _processAndUpload(String sosId, File file, String type) async {
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last;
      await _uploadBytes(sosId, bytes, type, ext);
      // Clean up after upload
      if (await file.exists()) await file.delete();
    } catch (e) {
      getIt<Talker>().error('EvidenceCaptureService: _processAndUpload failed', e);
    }
  }

  Future<void> _uploadBytes(String sosId, Uint8List bytes, String type, String ext) async {
    try {
      final uid = _supabase.auth.currentUser?.id ?? 'anonymous';
      final hash = await _encryptionService.hashFile(bytes);
      final encryptedBytes = await _encryptionService.encryptFile(bytes);
      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.$ext.enc';
      final storagePath = '$uid/$sosId/$fileName';

      await _supabase.storage.from('evidence').uploadBinary(storagePath, encryptedBytes);

      await _supabase.from('evidence_items').insert({
        'sos_id': sosId,
        'user_id': uid,
        'type': type,
        'file_name': fileName,
        'file_size_bytes': encryptedBytes.length,
        'storage_path': storagePath,
        'encrypted_hash': hash,
        'captured_at': DateTime.now().toIso8601String(),
      });
      getIt<Talker>().info('EvidenceCaptureService: Uploaded $type to $storagePath');
    } catch (e) {
      getIt<Talker>().error('EvidenceCaptureService: _uploadBytes failed', e);
    }
  }
}
