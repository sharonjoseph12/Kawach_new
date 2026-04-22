import 'package:isar/isar.dart';

part 'sos_alert_local.g.dart';

@collection
class SosAlertLocal {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String remoteId;
  
  late double lat;
  late double lng;
  late int batteryPct;
  late String status;
  late String triggerType;
  late DateTime createdAt;
  
  bool isSynced = false;
  DateTime? syncedAt;
}
