// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mesh_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MeshMessageImpl _$$MeshMessageImplFromJson(Map<String, dynamic> json) =>
    _$MeshMessageImpl(
      msgId: json['msgId'] as String,
      type: json['type'] as String,
      originUserId: json['originUserId'] as String,
      payload: json['payload'] as String,
      ttl: (json['ttl'] as num?)?.toInt() ?? 8,
      timestamp: DateTime.parse(json['timestamp'] as String),
      signature: json['signature'] as String?,
    );

Map<String, dynamic> _$$MeshMessageImplToJson(_$MeshMessageImpl instance) =>
    <String, dynamic>{
      'msgId': instance.msgId,
      'type': instance.type,
      'originUserId': instance.originUserId,
      'payload': instance.payload,
      'ttl': instance.ttl,
      'timestamp': instance.timestamp.toIso8601String(),
      'signature': instance.signature,
    };
