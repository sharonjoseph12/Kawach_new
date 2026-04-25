import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
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
          await Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              if (payload.type == PayloadType.BYTES && payload.bytes != null) {
                _handleReceivedData(payload.bytes!);
              }
            },
            onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
          );
          
          await Nearby().sendBytesPayload(id, Uint8List.fromList(utf8.encode(jsonStr)));
        },
        onConnectionResult: (String id, Status status) {},
        onDisconnected: (String id) {},
        serviceId: serviceId,
      );
      
      debugPrint('KAWACH MESH: Started advertising');
      return advertising;
    } catch (e) {
      debugPrint('KAWACH MESH: Failed to start advertising: $e');
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
      
      debugPrint('KAWACH MESH: Started discovery');
      return discovering;
    } catch (e) {
      debugPrint('KAWACH MESH: Failed to start discovery: $e');
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
      debugPrint('KAWACH MESH: Failed to decode mesh data: $e');
    }
  }

  Future<void> _relayMessageToCloud(MeshMessage msg) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = !connectivityResult.contains(ConnectivityResult.none);
      
      if (hasInternet) {
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
        debugPrint('KAWACH MESH: Relayed offline SOS to cloud for ${msg.originUserId}');

        try {
          final guardianData = await Supabase.instance.client
              .from('guardians')
              .select('contact_phone')
              .eq('user_id', msg.originUserId);
              
          final telephony = Telephony.instance;
          bool permissionsGranted = await Permission.sms.isGranted;
          
          if (permissionsGranted) {
            String googleMapsLink = "https://maps.google.com/?q=$lat,$lng";
            String message = "KAWACH MESH RELAY: An offline user nearby is in danger! Battery $battery%. Location: $googleMapsLink";
            
            for (var g in guardianData) {
              final phone = g['contact_phone'] as String?;
              if (phone != null && phone.isNotEmpty) {
                await telephony.sendSms(to: phone, message: message);
                debugPrint('KAWACH MESH: Bridged SMS to guardian $phone');
              }
            }
          }
        } catch (smsError) {
          debugPrint('KAWACH MESH: Failed to bridge SMS: $smsError');
        }
      }
    } catch (e) {
      debugPrint('KAWACH MESH: Failed to relay SOS to cloud: $e');
    }
  }
}
