import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

@lazySingleton
class SmsFallbackService {
  Future<void> dispatchOfflineDistress({
    required double lat,
    required double lng,
    required List<String> guardianPhones,
  }) async {
    final message =
        "KAWACH SOS! I am in danger. My last known location: https://maps.google.com/?q=$lat,$lng";

    bool permissionsGranted = await Permission.sms.isGranted;
    if (!permissionsGranted) {
      final status = await Permission.sms.request();
      permissionsGranted = status.isGranted;
    }

    if (!permissionsGranted) {
      debugPrint('KAWACH: SMS permission denied, cannot send offline SOS');
      return;
    }

    final telephony = Telephony.instance;

    for (var phone in guardianPhones) {
      try {
        final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
        debugPrint('KAWACH: Attempting to send offline SMS to $formattedPhone');
        await telephony.sendSms(
          to: formattedPhone, 
          message: message,
          statusListener: (status) {
            debugPrint('KAWACH: SMS Status for $formattedPhone -> $status');
          },
        );
        debugPrint('KAWACH: Offline SMS request submitted for $formattedPhone');
      } catch (e) {
        debugPrint('KAWACH: Failed to send offline SMS to $phone: $e');
      }
    }
  }
}
