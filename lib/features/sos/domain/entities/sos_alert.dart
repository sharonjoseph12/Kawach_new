import 'package:freezed_annotation/freezed_annotation.dart';

part 'sos_alert.freezed.dart';
part 'sos_alert.g.dart';

@freezed
class SosAlert with _$SosAlert {
  const factory SosAlert({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'latitude') required double lat,
    @JsonKey(name: 'longitude') required double lng,
    double? accuracy,
    @JsonKey(name: 'battery_pct') int? batteryPct,
    @Default('triggered') String status,
    @JsonKey(name: 'trigger_type') String? triggerType,
    @Default('online') String origin,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _SosAlert;

  factory SosAlert.fromJson(Map<String, dynamic> json) => _$SosAlertFromJson(json);
}
