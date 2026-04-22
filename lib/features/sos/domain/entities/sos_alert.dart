import 'package:freezed_annotation/freezed_annotation.dart';

part 'sos_alert.freezed.dart';
part 'sos_alert.g.dart';

@freezed
class SosAlert with _$SosAlert {
  const factory SosAlert({
    required String id,
    required String userId,
    required double lat,
    required double lng,
    double? accuracy,
    int? batteryPct,
    @Default('active') String status,
    String? triggerType,
    @Default('online') String origin,
    DateTime? resolvedAt,
    required DateTime createdAt,
  }) = _SosAlert;

  factory SosAlert.fromJson(Map<String, dynamic> json) => _$SosAlertFromJson(json);
}
