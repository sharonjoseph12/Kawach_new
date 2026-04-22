import 'package:freezed_annotation/freezed_annotation.dart';

part 'mesh_message.freezed.dart';
part 'mesh_message.g.dart';

@freezed
class MeshMessage with _$MeshMessage {
  const factory MeshMessage({
    required String msgId,
    required String type, // SOS / LOCATION / ACK
    required String originUserId,
    required String payload, // Encrypted base64
    @Default(8) int ttl,
    required DateTime timestamp,
    String? signature,
  }) = _MeshMessage;

  factory MeshMessage.fromJson(Map<String, dynamic> json) => _$MeshMessageFromJson(json);
}
