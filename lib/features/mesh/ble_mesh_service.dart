import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mesh_message.dart';
import 'dedup_cache.dart';

@LazySingleton()
class BleMeshService {
  static const MethodChannel _methodChannel = MethodChannel('kawach/ble_mesh_methods');
  static const EventChannel _eventChannel = EventChannel('kawach/ble_mesh_events');

  final DedupCache _cache = DedupCache();
  StreamSubscription? _scanSubscription;

  // Stream for upper layers to listen to incoming mesh SOS messages
  final _messageController = StreamController<MeshMessage>.broadcast();
  Stream<MeshMessage> get incomingMessages => _messageController.stream;

  Future<bool> startAdvertising(MeshMessage message) async {
    try {
      final jsonStr = jsonEncode(message.toJson());
      final bytes = utf8.encode(jsonStr);
      final base64Payload = base64Encode(bytes);

      final success = await _methodChannel.invokeMethod<bool>('startAdvertising', {
        'payload': base64Payload,
      });
      return success ?? false;
    } catch (e) {
      getIt<Talker>().error('BleMeshService: Failed to start advertising', e);
      return false;
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await _methodChannel.invokeMethod('stopAdvertising');
    } catch (e) {
      getIt<Talker>().error('BleMeshService: Failed to stop advertising', e);
    }
  }

  Future<bool> startScanning() async {
    try {
      final success = await _methodChannel.invokeMethod<bool>('startScanning');
      if (success == true) {
        _scanSubscription = _eventChannel.receiveBroadcastStream().listen((data) {
          if (data is String) {
            _handleDiscoveredData(data);
          }
        });
        return true;
      }
      return false;
    } catch (e) {
      getIt<Talker>().error('BleMeshService: Failed to start scanning', e);
      return false;
    }
  }

  void _handleDiscoveredData(String base64Data) {
    try {
      final bytes = base64Decode(base64Data);
      final jsonStr = utf8.decode(bytes);
      final msg = MeshMessage.fromJson(jsonDecode(jsonStr));
      
      if (!_cache.isSeen(msg.msgId)) {
        _cache.markSeen(msg.msgId);
        _messageController.add(msg); // Notify UI
        _relayMessageToCloud(msg);
        _relayMessage(msg);
      }
    } catch (e) {
      getIt<Talker>().error('BleMeshService: Failed to decode mesh data', e);
    }
  }

  Future<void> _relayMessageToCloud(MeshMessage msg) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = connectivityResult.any((r) => r == ConnectivityResult.mobile || r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);
      
      if (hasInternet) {
        // We have internet! Upload the victim's SOS packet immediately.
        await Supabase.instance.client.from('sos_alerts').insert({
          'id': msg.msgId,
          'user_id': msg.originUserId,
          'status': 'active',
          'trigger_type': 'ble_mesh',
          'encrypted_payload': msg.payload,
          'battery_level': 0, // Unknown
          'created_at': DateTime.now().toIso8601String(),
        });
        getIt<Talker>().info('BleMeshService: Successfully relayed offline SOS to cloud for user ${msg.originUserId}');
      }
    } catch (e) {
      getIt<Talker>().error('BleMeshService: Failed to relay SOS to cloud', e);
    }
  }

  void _relayMessage(MeshMessage msg) {
    if (msg.ttl > 0) {
      final relayedMsg = msg.copyWith(ttl: msg.ttl - 1);
      // Briefly advertise the relayed message
      startAdvertising(relayedMsg);
    }
  }

  Future<void> stop() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    try {
      await _methodChannel.invokeMethod('stopScanning');
      await _methodChannel.invokeMethod('stopAdvertising');
    } catch (_) {}
  }
}
