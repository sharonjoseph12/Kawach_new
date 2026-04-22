import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class KeyManager {
  final FlutterSecureStorage _storage;
  static const String _deviceKeyAlias = 'kawach_device_key';
  static const String _meshKeyPrefix = 'kawach_mesh_key_';

  KeyManager(this._storage);

  Future<SecretKey> getDeviceKey() async {
    final storedKey = await _storage.read(key: _deviceKeyAlias);
    if (storedKey == null) {
      return generateAndStoreDeviceKey();
    }
    return SecretKey(base64Decode(storedKey));
  }

  Future<SecretKey> generateAndStoreDeviceKey() async {
    final algorithm = AesCbc.with256bits(macAlgorithm: Hmac.sha256());
    final secretKey = await algorithm.newSecretKey();
    final bytes = await secretKey.extractBytes();
    await _storage.write(key: _deviceKeyAlias, value: base64Encode(bytes));
    return secretKey;
  }

  Future<void> storeMeshSessionKey(String peerId, SecretKey key) async {
    final bytes = await key.extractBytes();
    await _storage.write(
      key: '$_meshKeyPrefix$peerId',
      value: base64Encode(bytes),
    );
  }

  Future<SecretKey?> getMeshSessionKey(String peerId) async {
    final storedKey = await _storage.read(key: '$_meshKeyPrefix$peerId');
    if (storedKey == null) return null;
    return SecretKey(base64Decode(storedKey));
  }
}
