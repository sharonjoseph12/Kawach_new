import 'package:isar/isar.dart';

part 'evidence_local.g.dart';

@collection
class EvidenceLocal {
  Id id = Isar.autoIncrement;
  
  late String localPath;
  late String type;
  late String sosRemoteId;
  late int sizeBytes;
  late String hash;
  late DateTime capturedAt;
  
  bool isUploaded = false;
  String? remoteStoragePath;
}
