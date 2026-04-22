import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Background service to continuously listen for the "KAWACH HELP" distress phrase.
class WakeWordService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  
  // Custom distress phrases
  final List<String> _wakeWords = ['kawach', 'help me', 'sos', 'bachao'];

  /// Initializes the speech engine and asks for microphone permissions.
  Future<bool> initialize() async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) => debugPrint('🎤 [WAKE-WORD] Status -> $status'),
        onError: (errorNotification) => debugPrint('🎤 [WAKE-WORD] Error -> $errorNotification'),
      );
      return available;
    } catch (e) {
      debugPrint('🎤 [WAKE-WORD] Init Error: $e');
      return false;
    }
  }

  DateTime? _lastTriggerTime;

  /// Starts the continuous listening loop.
  Future<void> startListening({
    required VoidCallback onWakeWordDetected,
  }) async {
    if (_isListening || !_speechToText.isAvailable) return;

    _isListening = true;
    debugPrint('🎤 [WAKE-WORD] Listening for distress phrases...');

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        final words = ' ${result.recognizedWords.toLowerCase()} ';

        // Word-boundary matching: pad with spaces to avoid partial matches.
        // 'cosmos' won't match ' sos ', 'progress' won't match ' help '.
        final bool threatDetected = _wakeWords.any((w) => words.contains(' $w '));

        // Cooldown: ignore repeated triggers within 30 seconds
        final now = DateTime.now();
        final recentlyTriggered = _lastTriggerTime != null &&
            now.difference(_lastTriggerTime!).inSeconds < 30;

        if (threatDetected && _isListening && !recentlyTriggered) {
          _lastTriggerTime = now;
          debugPrint('‼️ [WAKE-WORD] DISTRESS WAKE WORD DETECTED: "${result.recognizedWords}"');
          _isListening = false;
          stopListening();
          onWakeWordDetected();
        }
      },
      listenFor: const Duration(hours: 1),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speechToText.stop();
    debugPrint('🎤 [WAKE-WORD] Stopped listening.');
  }
}
