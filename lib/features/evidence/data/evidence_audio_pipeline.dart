import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;

class EvidenceAudioPipeline {
  static final EvidenceAudioPipeline _instance = EvidenceAudioPipeline._internal();
  factory EvidenceAudioPipeline() => _instance;
  EvidenceAudioPipeline._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _chunkTimer;
  bool _isRecording = false;
  String? _currentSosId;
  String? _userId;

  final _algorithm = AesGcm.with256bits();
  SecretKey? _sessionKey;

  Future<void> startContinuousRecording(String sosId) async {
    if (_isRecording) return;
    
    if (!await _audioRecorder.hasPermission()) {
      return; // Fallback or notify UI if possible
    }

    _currentSosId = sosId;
    _userId = Supabase.instance.client.auth.currentUser?.id;
    if (_userId == null) return;

    _sessionKey = await _algorithm.newSecretKey();
    _isRecording = true;
    _recordNextChunk();
  }

  Future<void> _recordNextChunk() async {
    if (!_isRecording) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final evidenceDir = Directory('${dir.path}/kawach_evidence');
      if (!evidenceDir.existsSync()) evidenceDir.createSync();
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${evidenceDir.path}/audio_evidence_$timestamp.m4a';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: filePath,
      );

      // Schedule stop and upload after 15 seconds
      _chunkTimer = Timer(const Duration(seconds: 15), () async {
        if (!_isRecording) return;
        
        final path = await _audioRecorder.stop();
        if (path != null) {
          final originalFile = File(path);
          final bytes = await originalFile.readAsBytes();
          
          // Encrypt file at rest
          if (_sessionKey != null) {
            final secretBox = await _algorithm.encrypt(bytes, secretKey: _sessionKey!);
            final encFile = File('$path.enc');
            await encFile.writeAsBytes(secretBox.concatenation());
            // Delete plaintext file
            await originalFile.delete();
            _uploadChunk(encFile, timestamp);
          } else {
            _uploadChunk(originalFile, timestamp);
          }
        }
        
        // Loop recursively to start the next chunk
        _recordNextChunk();
      });
    } catch (_) {
      _isRecording = false;
    }
  }

  Future<void> _uploadChunk(File encryptedFile, int timestamp) async {
    if (_userId == null) return;
    
    try {
      final fileName = 'audio_evidence_$timestamp.m4a';
      final storagePath = '$_userId/$_currentSosId/$fileName';

      // Decrypt in memory just before upload
      List<int> bytesToUpload;
      if (encryptedFile.path.endsWith('.enc') && _sessionKey != null) {
        final encBytes = await encryptedFile.readAsBytes();
        final secretBox = SecretBox.fromConcatenation(encBytes, nonceLength: 12, macLength: 16);
        bytesToUpload = await _algorithm.decrypt(secretBox, secretKey: _sessionKey!);
      } else {
        bytesToUpload = await encryptedFile.readAsBytes();
      }
      final uint8Bytes = Uint8List.fromList(bytesToUpload);

      // Ensure 'evidence' bucket exists (assumed pre-configured in Supabase)
      await Supabase.instance.client.storage
          .from('evidence')
          .uploadBinary(storagePath, uint8Bytes, fileOptions: const FileOptions(upsert: false, contentType: 'audio/m4a'));

      // Log into Vault DB
      final hash = crypto.sha256.convert(uint8Bytes);
      final hashHex = hash.toString();

      await Supabase.instance.client.from('evidence_items').insert({
        'user_id': _userId,
        'sos_id': _currentSosId,
        'type': 'audio',
        'file_name': fileName,
        'file_size_bytes': uint8Bytes.length,
        'storage_path': storagePath,
        'file_hash': hashHex, // Real SHA-256 hash
        'captured_at': DateTime.now().toIso8601String(),
      });

      // Optionally delete local original, or keep it for the Local Vault tab
      // Let's keep it locally as well for the EvidenceVaultPage "Local" tab.

    } catch (_) {
      // Cloud upload failed, file remains securely on local device
    }
  }

  Future<void> stopContinuousRecording() async {
    _isRecording = false;
    _chunkTimer?.cancel();
    
    if (await _audioRecorder.isRecording()) {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final originalFile = File(path);
        final bytes = await originalFile.readAsBytes();
        
        if (_sessionKey != null) {
          final secretBox = await _algorithm.encrypt(bytes, secretKey: _sessionKey!);
          final encFile = File('$path.enc');
          await encFile.writeAsBytes(secretBox.concatenation());
          await originalFile.delete();
          _uploadChunk(encFile, DateTime.now().millisecondsSinceEpoch);
        } else {
          _uploadChunk(originalFile, DateTime.now().millisecondsSinceEpoch);
        }
      }
    }
  }

  void dispose() {
    stopContinuousRecording();
    _audioRecorder.dispose();
  }

  Future<void> uploadPending() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final evidenceDir = Directory('${dir.path}/kawach_evidence');
      if (!evidenceDir.existsSync()) return;

      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      final files = evidenceDir.listSync().whereType<File>().toList();
      for (final file in files) {
        final name = file.path.split('/').last;
        // Don't upload temporary files actively being written, check age or extension
        if (name.endsWith('.m4a') || name.endsWith('.enc')) {
          final storagePath = '$uid/offline_sync/$name';
          
          List<int> bytesToUpload;
          try {
            if (name.endsWith('.enc') && _sessionKey != null) {
              final encBytes = await file.readAsBytes();
              final secretBox = SecretBox.fromConcatenation(encBytes, nonceLength: 12, macLength: 16);
              bytesToUpload = await _algorithm.decrypt(secretBox, secretKey: _sessionKey!);
            } else {
              bytesToUpload = await file.readAsBytes();
            }
          } catch (_) {
            bytesToUpload = await file.readAsBytes();
          }

          await Supabase.instance.client.storage
              .from('evidence')
              .uploadBinary(storagePath, Uint8List.fromList(bytesToUpload), fileOptions: const FileOptions(upsert: false, contentType: 'audio/m4a'));
          
          await file.delete();
        }
      }
    } catch (_) {}
  }
}
