import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';
import 'models/sos_alert_local.dart';
import 'models/evidence_local.dart';

@lazySingleton
class LocalDatabase {
  late final Isar isar;

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [SosAlertLocalSchema, EvidenceLocalSchema],
      directory: dir.path,
    );
  }

  Future<void> saveSosAlert(SosAlertLocal alert) async {
    await isar.writeTxn(() async {
      await isar.sosAlertLocals.put(alert);
    });
  }

  Future<void> saveEvidence(EvidenceLocal evidence) async {
    await isar.writeTxn(() async {
      await isar.evidenceLocals.put(evidence);
    });
  }

  Future<List<SosAlertLocal>> getUnsyncedAlerts() async {
    return await isar.sosAlertLocals.filter().isSyncedEqualTo(false).findAll();
  }

  Future<List<EvidenceLocal>> getUnuploadedEvidence() async {
    return await isar.evidenceLocals.filter().isUploadedEqualTo(false).findAll();
  }
}
