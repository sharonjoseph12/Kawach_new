import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

@lazySingleton
class LoggerService {
  final Talker talker = TalkerFlutter.init();

  void info(String message) {
    talker.info(message);
  }

  void warning(String message) {
    talker.warning(message);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    talker.error(message, error, stackTrace);
    Sentry.captureException(error, stackTrace: stackTrace);
  }

  void debug(String message) {
    talker.debug(message);
  }

  void critical(String message, [dynamic error, StackTrace? stackTrace]) {
    talker.critical(message, error, stackTrace);
    Sentry.captureException(error, stackTrace: stackTrace);
  }
}
