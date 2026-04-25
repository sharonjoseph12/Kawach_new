import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kawach/core/services/logger_service.dart';
import 'package:kawach/app/di/injection.dart';

import 'package:injectable/injectable.dart';

@lazySingleton
class SmsFallbackService {
  static const MethodChannel _smsChannel = MethodChannel('com.kawach/sms');

  Future<void> dispatchOfflineDistress({
    required double lat,
    required double lng,
    required List<String> guardianPhones,
  }) async {
    final message = "URGENT SOS! I am in danger. My last known location is: https://maps.google.com/?q=$lat,$lng";
    
    for (var phone in guardianPhones) {
      // 1. Try SMS First
      try {
        await _smsChannel.invokeMethod('sendSms', {
          'phone': phone,
          'message': message,
        });
        getIt<LoggerService>().info('📱 Fallback SMS sent successfully to $phone');
      } catch (e) {
        getIt<LoggerService>().error('Failed to send fallback SMS to $phone', e, null);
      }
      
      // 2. Send WhatsApp via Twilio
      await _sendTwilioWhatsApp(phone, lat, lng);
    }
  }

  Future<void> _sendTwilioWhatsApp(String toPhone, double lat, double lng) async {
    try {
      final accountSid = dotenv.env['TWILIO_ACCOUNT_SID'];
      final authToken = dotenv.env['TWILIO_AUTH_TOKEN'];
      final fromNumber = dotenv.env['TWILIO_WHATSAPP_NUMBER'];
      
      if (accountSid == null || authToken == null || fromNumber == null) return;

      final dio = Dio();
      final auth = base64Encode(utf8.encode('$accountSid:$authToken'));
      
      final String formattedPhone = toPhone.startsWith('+') ? toPhone : '+91$toPhone';

      await dio.post(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
        options: Options(
          headers: {
            'Authorization': 'Basic $auth',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'From': 'whatsapp:$fromNumber',
          'To': 'whatsapp:$formattedPhone',
          'Body': '🚨 URGENT SOS! I am in danger. Live Tracking: https://maps.google.com/?q=$lat,$lng',
        },
      );
      getIt<LoggerService>().info('📱 Fallback WhatsApp sent successfully to $formattedPhone');
    } catch (e) {
      getIt<LoggerService>().error('Failed to send Twilio WhatsApp', e, null);
    }
  }
}
