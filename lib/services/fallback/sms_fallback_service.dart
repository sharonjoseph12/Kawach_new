import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to handle SMS fallbacks when the internet is unavailable.
class SmsFallbackService {
  
  /// Formats the SOS payload and attempts to launch the device's native SMS application.
  static Future<void> initiateOfflineSos({
    required double lat,
    required double lng,
    required int battery,
    required String triggerType,
    List<String> emergencyContacts = const ['112'], // Default emergency number in India
  }) async {
    final baseUrl = 'https://maps.google.com/?q=$lat,$lng';
    final message = 'SOS! I am in danger. My battery is at $battery%.\nLocation: $baseUrl\nTriggered via: $triggerType';
    
    // Construct the comma-separated or semicolon-separated list of numbers
    final separator = Platform.isIOS ? ',' : ';';
    final recipients = emergencyContacts.join(separator);
    
    final uriString = 'sms:$recipients?body=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(uriString);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('SMS Fallback launched successfully.');
      } else {
        debugPrint('Could not launch SMS application. URI: $uriString');
      }
    } catch (e) {
      debugPrint('Error launching SMS Fallback: $e');
    }
  }
}
