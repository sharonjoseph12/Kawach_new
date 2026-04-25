// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SosAlertImpl _$$SosAlertImplFromJson(Map<String, dynamic> json) =>
    _$SosAlertImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      lat: (json['latitude'] as num).toDouble(),
      lng: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      batteryPct: (json['battery_pct'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'triggered',
      triggerType: json['trigger_type'] as String?,
      origin: json['origin'] as String? ?? 'online',
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$SosAlertImplToJson(_$SosAlertImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'latitude': instance.lat,
      'longitude': instance.lng,
      'accuracy': instance.accuracy,
      'battery_pct': instance.batteryPct,
      'status': instance.status,
      'trigger_type': instance.triggerType,
      'origin': instance.origin,
      'resolved_at': instance.resolvedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
