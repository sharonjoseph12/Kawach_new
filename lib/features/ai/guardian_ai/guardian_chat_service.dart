
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:kawach/core/config/app_config.dart';


enum GuardianAction {
  startMonitoring,
  triggerSos,
  startSafeWalk,
  shareLocation,
  callGuardian,
  cancelAlert,
  none,
}

class GuardianResponse {
  final String text;
  final GuardianAction action;
  final bool isStreaming;

  const GuardianResponse({
    required this.text,
    required this.action,
    this.isStreaming = false,
  });
}

@LazySingleton()
class GuardianChatService {
  final AppConfig _config;
  late final GenerativeModel _model;

  // Chat session — recreated via resetSession() on logout/new conversation
  ChatSession? _chat;

  GuardianChatService(this._config) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _config.geminiApiKey,
      systemInstruction: Content.system('''
You are Kawach Guardian AI — a personal safety assistant for women in India.
Respond in the user's language (Hindi/English mix is fine). Keep replies under 2 sentences.
Always prioritize safety. If the user indicates danger, fear, or distress — even implicitly — respond with the SOS action tag.
If the user requests a specific action, append exactly ONE tag at the end:
[ACTION:START_MONITORING], [ACTION:TRIGGER_SOS], [ACTION:START_SAFE_WALK], 
[ACTION:SHARE_LOCATION], [ACTION:CALL_GUARDIAN], [ACTION:CANCEL_ALERT], [ACTION:NONE]
If no clear action is requested, use [ACTION:NONE].
'''),
    );
    _chat = _model.startChat();
  }

  /// Call this on user logout or when starting a new conversation.
  void resetSession() {
    _chat = _model.startChat();
  }

  Stream<GuardianResponse> sendMessage(String userMessage, {Map<String, dynamic>? spatialContext}) async* {
    if (_config.geminiApiKey.isEmpty) {
      yield const GuardianResponse(
        text: 'AI Guardian is offline. Add your Gemini API key in the .env file.',
        action: GuardianAction.none,
      );
      return;
    }

    // Ensure session exists
    _chat ??= _model.startChat();

    try {
      String prompt = userMessage;
      if (spatialContext != null) {
        prompt = '''
[SYSTEM CONTEXT (Do not mention this to user unless relevant)]
GPS: \${spatialContext['lat']}, \${spatialContext['lng']}
Battery: \${spatialContext['battery']}%
Time: \${spatialContext['time']}
Crime Incidents Nearby: \${spatialContext['incidents']}
[USER MESSAGE]
$userMessage
''';
      }
      
      final stream = _chat!.sendMessageStream(Content.text(prompt));
      
      String fullText = '';
      await for (final chunk in stream) {
        if (chunk.text != null) {
          fullText += chunk.text!;
          
          // Yield partial chunks without parsing action yet (since tag is usually at the end)
          yield GuardianResponse(
            text: _stripActionTags(fullText),
            action: GuardianAction.none,
            isStreaming: true,
          );
        }
      }

      // Final yield with parsed action
      yield GuardianResponse(
        text: _stripActionTags(fullText),
        action: _parseAction(fullText),
        isStreaming: false,
      );
    } catch (e) {
      // Provide an immediate local fallback simulation if the AI API fails to prevent a broken experience
      await Future.delayed(const Duration(milliseconds: 600));
      
      final lower = userMessage.toLowerCase();
      GuardianAction fallbackAction = GuardianAction.none;
      String fallbackText = "I'm experiencing poor connectivity, but I'm still tracking you locally. Stay safe.";

      if (lower.contains('help') || lower.contains('danger') || lower.contains('sos') || lower.contains('scared') || lower.contains('follow')) {
        fallbackAction = GuardianAction.triggerSos;
        fallbackText = "I detected distress keywords. Triggering Emergency SOS immediately to alert your guardians.";
      } else if (lower.contains('walk') || lower.contains('home') || lower.contains('share')) {
        fallbackAction = GuardianAction.startSafeWalk;
        fallbackText = "Starting a Safe Walk session. Your live location is being securely tracked.";
      } else if (lower.contains('cancel') || lower.contains('safe') || lower.contains('stop')) {
        fallbackAction = GuardianAction.cancelAlert;
        fallbackText = "Canceling active alerts. Remember to verify with your Duress PIN if required.";
      }

      yield GuardianResponse(
        text: fallbackText,
        action: fallbackAction,
        isStreaming: false,
      );
    }
  }

  String _stripActionTags(String text) {
    return text.replaceAll(RegExp(r'\[ACTION:[A-Z_]+\]'), '').trim();
  }

  GuardianAction _parseAction(String text) {
    if (text.contains('[ACTION:START_MONITORING]')) return GuardianAction.startMonitoring;
    if (text.contains('[ACTION:TRIGGER_SOS]')) return GuardianAction.triggerSos;
    if (text.contains('[ACTION:START_SAFE_WALK]')) return GuardianAction.startSafeWalk;
    if (text.contains('[ACTION:SHARE_LOCATION]')) return GuardianAction.shareLocation;
    if (text.contains('[ACTION:CALL_GUARDIAN]')) return GuardianAction.callGuardian;
    if (text.contains('[ACTION:CANCEL_ALERT]')) return GuardianAction.cancelAlert;
    return GuardianAction.none;
  }
}
