import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:telephony/telephony.dart';
import 'mesh_message.dart';
import 'dedup_cache.dart';

@LazySingleton()
class NearbyMeshService {
  // P2P_CLUSTER is the only strategy that supports simultaneous
  // advertising + discovery on the same device.
  final Strategy strategy = Strategy.P2P_CLUSTER;
  final String serviceId = "com.kawach.kawach";
  
  final DedupCache _cache = DedupCache();

  final _messageController = StreamController<MeshMessage>.broadcast();
  Stream<MeshMessage> get incomingMessages => _messageController.stream;

  /// SENDER (offline phone): Advertise and send SOS payload to anyone who connects.
  Future<bool> startAdvertising(MeshMessage message) async {
    try {
      final jsonStr = jsonEncode(message.toJson());
      debugPrint('KAWACH MESH TX: Preparing to advertise. Payload length=${jsonStr.length}');

      // Stop any previous advertising and clear orphaned endpoints
      try { 
        await Nearby().stopAdvertising(); 
        await Nearby().stopAllEndpoints();
      } catch (_) {}

      bool advertising = await Nearby().startAdvertising(
        "KawachSOS",
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) async {
          debugPrint('KAWACH MESH TX: Connection initiated by $id (${info.endpointName}). Auto-accepting...');
          await Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              debugPrint('KAWACH MESH TX: Got ACK from relay node');
            },
            onPayloadTransferUpdate: (endpointId, update) {},
          );
        },
        onConnectionResult: (String id, Status status) async {
          debugPrint('KAWACH MESH TX: Connection result with $id = $status');
          if (status == Status.CONNECTED) {
            debugPrint('KAWACH MESH TX: ✅ CONNECTED! Sending SOS payload now...');
            final bytes = Uint8List.fromList(utf8.encode(jsonStr));
            await Nearby().sendBytesPayload(id, bytes);
            debugPrint('KAWACH MESH TX: ✅ Payload sent (${bytes.length} bytes)');
          } else {
            debugPrint('KAWACH MESH TX: ❌ Connection REJECTED: $status');
          }
        },
        onDisconnected: (String id) {
          debugPrint('KAWACH MESH TX: Disconnected from $id');
        },
        serviceId: serviceId,
      );
      
      debugPrint('KAWACH MESH TX: Advertising started = $advertising');
      return advertising;
    } catch (e) {
      debugPrint('KAWACH MESH TX: ❌ Failed to advertise: $e');
      return false;
    }
  }

  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
  }

  /// RECEIVER (phone with internet): Discover nearby SOS advertisers and relay.
  Future<bool> startScanning() async {
    try {
      // Stop previous discovery and clear orphaned endpoints
      try { 
        await Nearby().stopDiscovery(); 
        await Nearby().stopAllEndpoints();
      } catch (_) {}

      debugPrint('KAWACH MESH RX: Starting discovery...');

      bool discovering = await Nearby().startDiscovery(
        "KawachRelay",
        strategy,
        onEndpointFound: (String id, String userName, String serviceId) async {
          debugPrint('KAWACH MESH RX: 🔍 Found device "$userName" ($id). Connecting...');
          
          try {
            await Nearby().requestConnection(
              "KawachRelay",
              id,
              onConnectionInitiated: (String connId, ConnectionInfo info) async {
                debugPrint('KAWACH MESH RX: Handshake with ${info.endpointName} ($connId). Accepting...');
                await Nearby().acceptConnection(
                  connId,
                  onPayLoadRecieved: (endpointId, payload) {
                    debugPrint('KAWACH MESH RX: 📦 PAYLOAD RECEIVED! type=${payload.type}, bytes=${payload.bytes?.length}');
                    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
                      _handleReceivedData(payload.bytes!);
                    }
                  },
                  onPayloadTransferUpdate: (endpointId, update) {
                    debugPrint('KAWACH MESH RX: Transfer ${update.status} (${update.bytesTransferred}/${update.totalBytes})');
                  },
                );
              },
              onConnectionResult: (String connId, Status status) {
                debugPrint('KAWACH MESH RX: Connection result = $status');
                if (status == Status.CONNECTED) {
                  debugPrint('KAWACH MESH RX: ✅ CONNECTED to offline node!');
                } else {
                  debugPrint('KAWACH MESH RX: ❌ Connection failed: $status');
                }
              },
              onDisconnected: (String connId) {
                debugPrint('KAWACH MESH RX: Disconnected from $connId');
              },
            );
          } catch (e) {
            debugPrint('KAWACH MESH RX: requestConnection failed: $e');
          }
        },
        onEndpointLost: (String? id) {
          debugPrint('KAWACH MESH RX: Lost endpoint $id');
        },
        serviceId: serviceId,
      );
      
      debugPrint('KAWACH MESH RX: Discovery started = $discovering');
      return discovering;
    } catch (e) {
      debugPrint('KAWACH MESH RX: ❌ Failed to start discovery: $e');
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
      debugPrint('KAWACH MESH RX: Decoded JSON: $jsonStr');
      
      final msg = MeshMessage.fromJson(jsonDecode(jsonStr));
      debugPrint('KAWACH MESH RX: Parsed MeshMessage: type=${msg.type}, payload=${msg.payload}');
      
      if (!_cache.isSeen(msg.msgId)) {
        _cache.markSeen(msg.msgId);
        _messageController.add(msg); 
        debugPrint('KAWACH MESH RX: 🚨 NEW SOS! Relaying...');
        _relayMessage(msg);
      } else {
        debugPrint('KAWACH MESH RX: Duplicate msgId=${msg.msgId}, skipping');
      }
    } catch (e) {
      debugPrint('KAWACH MESH RX: ❌ Failed to decode: $e');
    }
  }

  /// Relay: Send SMS FIRST (critical path), then try cloud sync (best effort).
  Future<void> _relayMessage(MeshMessage msg) async {
    debugPrint('KAWACH MESH RELAY: Starting relay for msg ${msg.msgId}');

    // ── STEP 1: Parse payload ──
    double lat = 0.0;
    double lng = 0.0;
    int battery = 0;
    String phonesStr = '';
    
    try {
      final parts = msg.payload.split(',');
      for (final part in parts) {
        final colonIdx = part.indexOf(':');
        if (colonIdx > 0) {
          final key = part.substring(0, colonIdx);
          final value = part.substring(colonIdx + 1);
          if (key == 'lat') lat = double.tryParse(value) ?? 0.0;
          if (key == 'lng') lng = double.tryParse(value) ?? 0.0;
          if (key == 'bat') battery = int.tryParse(value) ?? 0;
          if (key == 'phones') phonesStr = value;
        }
      }
    } catch (e) {
      debugPrint('KAWACH MESH RELAY: Parse error: $e');
    }
    
    debugPrint('KAWACH MESH RELAY: Parsed — lat=$lat, lng=$lng, bat=$battery, phones=$phonesStr');

    // ── STEP 2: SEND SMS IMMEDIATELY (highest priority) ──
    if (phonesStr.isNotEmpty) {
      final phones = phonesStr.split('|').where((p) => p.isNotEmpty).toList();
      debugPrint('KAWACH MESH RELAY: Sending SMS to ${phones.length} guardians...');
      
      for (var phone in phones) {
        try {
          final telephony = Telephony.instance;
          String googleMapsLink = "https://maps.google.com/?q=$lat,$lng";
          String message = "🚨 KAWACH SOS RELAY: Someone nearby needs help! "
              "Battery $battery%. Location: $googleMapsLink";
          
          await telephony.sendSms(to: phone, message: message);
          debugPrint('KAWACH MESH RELAY: ✅ SMS sent to $phone');
        } catch (e) {
          debugPrint('KAWACH MESH RELAY: ❌ SMS failed for $phone: $e');
        }
      }
    } else {
      debugPrint('KAWACH MESH RELAY: ⚠️ No phone numbers in payload!');
    }

    // ── STEP 3: Cloud sync (best effort, non-blocking) ──
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = !connectivityResult.contains(ConnectivityResult.none);
      
      if (hasInternet) {
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
        debugPrint('KAWACH MESH RELAY: ✅ Cloud sync done');
      }
    } catch (e) {
      debugPrint('KAWACH MESH RELAY: Cloud sync failed (non-fatal): $e');
    }
  }
}
