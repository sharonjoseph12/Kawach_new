import 'dart:typed_data';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:injectable/injectable.dart';
import 'key_manager.dart';

@lazySingleton
class EncryptionService {
  final KeyManager _keyManager;
  final _algorithm = AesCbc.with256bits(macAlgorithm: Hmac.sha256());

  EncryptionService(this._keyManager);

  Future<Uint8List> encryptFile(Uint8List plaintext) async {
    final secretKey = await _keyManager.getDeviceKey();
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
    );
    return Uint8List.fromList(secretBox.concatenation());
  }

  Future<Uint8List> decryptFile(Uint8List ciphertext) async {
    final secretKey = await _keyManager.getDeviceKey();
    final secretBox = SecretBox.fromConcatenation(
      ciphertext,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    final decrypted = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return Uint8List.fromList(decrypted);
  }

  Future<SecretKey> generateMeshKey() async {
    return _algorithm.newSecretKey();
  }

  Future<String> encryptMeshPayload(String payload, SecretKey key) async {
    final secretBox = await _algorithm.encrypt(
      utf8.encode(payload),
      secretKey: key,
    );
    return base64Encode(secretBox.concatenation());
  }

  Future<String> decryptMeshPayload(String encrypted, SecretKey key) async {
    final ciphertext = base64Decode(encrypted);
    final secretBox = SecretBox.fromConcatenation(
      ciphertext,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    final decrypted = await _algorithm.decrypt(
      secretBox,
      secretKey: key,
    );
    return utf8.decode(decrypted);
  }

  Future<String> hashFile(Uint8List bytes) async {
    final hashAlgorithm = Sha256();
    final hash = await hashAlgorithm.hash(bytes);
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
