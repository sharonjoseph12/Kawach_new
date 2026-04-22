// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SosAlertImpl _$$SosAlertImplFromJson(Map<String, dynamic> json) =>
    _$SosAlertImpl(
      id: json['id'] as String,
      userId: (json['user_id'] ?? json['userId']) as String,
      lat: ((json['latitude'] ?? json['lat']) as num).toDouble(),
      lng: ((json['longitude'] ?? json['lng']) as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      batteryPct: ((json['battery_pct'] ?? json['batteryPct']) as num?)?.toInt(),
      status: json['status'] as String? ?? 'triggered',
      triggerType: (json['trigger_type'] ?? json['triggerType']) as String?,
      origin: json['origin'] as String? ?? 'online',
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      createdAt: DateTime.parse(
          (json['created_at'] ?? json['createdAt']) as String),
    );

Map<String, dynamic> _$$SosAlertImplToJson(_$SosAlertImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'lat': instance.lat,
      'lng': instance.lng,
      'accuracy': instance.accuracy,
      'batteryPct': instance.batteryPct,
      'status': instance.status,
      'triggerType': instance.triggerType,
      'origin': instance.origin,
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
