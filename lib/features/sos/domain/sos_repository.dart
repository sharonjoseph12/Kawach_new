import 'package:fpdart/fpdart.dart';
import 'package:kawach/core/error/failures.dart';
import '../domain/entities/sos_alert.dart';

abstract class SosRepository {
  Future<Either<Failure, SosAlert>> triggerSOS({
    required double lat,
    required double lng,
    required int battery,
    required String triggerType,
  });
  Future<Either<Failure, void>> cancelSOS(String sosId, String reason);
  Stream<SosAlert?> listenToActiveSOS(String userId);
}
