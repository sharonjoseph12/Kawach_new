import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'mesh_message.dart';
import 'dedup_cache.dart';

@LazySingleton()
class NearbyMeshService {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  final String serviceId = "com.kawach.mesh.offline_sos";
  
  final DedupCache _cache = DedupCache();

  // Stream for upper layers
  final _messageController = StreamController<MeshMessage>.broadcast();
  Stream<MeshMessage> get incomingMessages => _messageController.stream;

  Future<bool> startAdvertising(MeshMessage message) async {
    try {
      final jsonStr = jsonEncode(message.toJson());
      
      bool advertising = await Nearby().startAdvertising(
        "KawachNode",
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) async {
          // Auto-accept all connections for offline relay
          await Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              if (payload.type == PayloadType.BYTES && payload.bytes != null) {
                _handleReceivedData(payload.bytes!);
              }
            },
            onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
          );
          
          // Once connected, immediately send the SOS payload
          await Nearby().sendBytesPayload(id, Uint8List.fromList(utf8.encode(jsonStr)));
        },
        onConnectionResult: (String id, Status status) {},
        onDisconnected: (String id) {},
        serviceId: serviceId,
      );
      
      getIt<Talker>().info('NearbyMeshService: Started advertising');
      return advertising;
    } catch (e) {
      getIt<Talker>().error('NearbyMeshService: Failed to start advertising', e);
      return false;
    }
  }

  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
  }

  Future<bool> startScanning() async {
    try {
      bool discovering = await Nearby().startDiscovery(
        "KawachNode",
        strategy,
        onEndpointFound: (String id, String userName, String serviceId) async {
          // Found a Kawach node in distress, connect to receive payload
          await Nearby().requestConnection(
            "RelayNode",
            id,
            onConnectionInitiated: (id, info) async {
              await Nearby().acceptConnection(
                id,
                onPayLoadRecieved: (endpointId, payload) {
                  if (payload.type == PayloadType.BYTES && payload.bytes != null) {
                    _handleReceivedData(payload.bytes!);
                  }
                },
                onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
              );
            },
            onConnectionResult: (id, status) {},
            onDisconnected: (id) {},
          );
        },
        onEndpointLost: (String? id) {},
        serviceId: serviceId,
      );
      
      getIt<Talker>().info('NearbyMeshService: Started discovery');
      return discovering;
    } catch (e) {
      getIt<Talker>().error('NearbyMeshService: Failed to start discovery', e);
      return false;
    }
  }

  Future<void> stopScanning() async {
    await Nearby().stopDiscovery();
  }

  Future<void> stopAll() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
  }

  void _handleReceivedData(Uint8List bytes) {
    try {
      final jsonStr = utf8.decode(bytes);
      final msg = MeshMessage.fromJson(jsonDecode(jsonStr));
      
      if (!_cache.isSeen(msg.msgId)) {
        _cache.markSeen(msg.msgId);
        _messageController.add(msg); 
        _relayMessageToCloud(msg);
      }
    } catch (e) {
      getIt<Talker>().error('NearbyMeshService: Failed to decode mesh data', e);
    }
  }

  Future<void> _relayMessageToCloud(MeshMessage msg) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = !connectivityResult.contains(ConnectivityResult.none);
      
      if (hasInternet) {
        // Parse coordinates from payload format: "lat:X,lng:Y,bat:Z"
        double lat = 0.0;
        double lng = 0.0;
        int battery = 0;
        try {
          final parts = msg.payload.split(',');
          for (final part in parts) {
            final kv = part.split(':');
            if (kv.length == 2) {
              if (kv[0] == 'lat') lat = double.tryParse(kv[1]) ?? 0.0;
              if (kv[0] == 'lng') lng = double.tryParse(kv[1]) ?? 0.0;
              if (kv[0] == 'bat') battery = int.tryParse(kv[1]) ?? 0;
            }
          }
        } catch (_) {}

        await Supabase.instance.client.from('sos_alerts').insert({
          'user_id': msg.originUserId,
          'latitude': lat,
          'longitude': lng,
          'status': 'triggered',
          'trigger_type': 'nearby_mesh',
          'battery_pct': battery,
          'origin': 'mesh_relay',
          'created_at': DateTime.now().toIso8601String(),
        });
        getIt<Talker>().info('NearbyMeshService: Successfully relayed offline SOS to cloud for user ${msg.originUserId}');
      }
    } catch (e) {
      getIt<Talker>().error('NearbyMeshService: Failed to relay SOS to cloud', e);
    }
  }
}
