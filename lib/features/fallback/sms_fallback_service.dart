import 'package:flutter/services.dart';
import 'package:kawach/core/services/logger_service.dart';
import 'package:kawach/app/di/injection.dart';

class SmsFallbackService {
  static const MethodChannel _smsChannel = MethodChannel('com.kawach/sms');

  Future<void> dispatchOfflineDistress({
    required double lat,
    required double lng,
    required List<String> guardianPhones,
  }) async {
    final message = "URGENT SOS! I am in danger. My last known location is: https://maps.google.com/?q=$lat,$lng";
    
    for (var phone in guardianPhones) {
      try {
        await _smsChannel.invokeMethod('sendSms', {
          'phone': phone,
          'message': message,
        });
        getIt<LoggerService>().info('📱 Fallback SMS sent successfully to $phone');
      } catch (e) {
        getIt<LoggerService>().error('Failed to send fallback SMS to $phone', e, null);
      }
    }
  }
}
