import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:kawach/features/sos/domain/sos_repository.dart';

class SmartwatchAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  int _clickCount = 0;
  Timer? _decayTimer;
  static const int _clickThreshold = 3;
  static const Duration _decayDuration = Duration(seconds: 3);

  SmartwatchAudioHandler() {
    // Show a silent active protection notification
    mediaItem.add(
      const MediaItem(
        id: 'kawach_active_protection',
        album: 'KAWACH Safety',
        title: 'Guardian AI Active',
        artist: 'KAWACH',
        duration: Duration(hours: 24),
        artUri: null,
      ),
    );

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: AudioProcessingState.ready,
        playing: false,
      ),
    );
  }

  void _handleMediaClick() {
    _clickCount++;
    getIt<Talker>().info('Smartwatch Button Clicked. Count: $_clickCount');

    _decayTimer?.cancel();
    _decayTimer = Timer(_decayDuration, () {
      _clickCount = 0;
    });

    if (_clickCount >= _clickThreshold) {
      _triggerSosFromSmartwatch();
      _clickCount = 0;
    }
  }

  Future<void> _triggerSosFromSmartwatch() async {
    getIt<Talker>().critical('Smartwatch SOS Triggered via Media Buttons!');
    
    // Vibrate phone to acknowledge successful trigger to the user
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 500]);
    }

    try {
      // Fetch real GPS and battery instead of dummy values
      double lat = 0.0, lng = 0.0;
      int battery = 50;
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {}
      try {
        battery = await Battery().batteryLevel;
      } catch (_) {}

      final sosRepo = getIt<SosRepository>();
      await sosRepo.triggerSOS(
        lat: lat, 
        lng: lng, 
        battery: battery, 
        triggerType: 'smartwatch_media',
      );
    } catch (e) {
      getIt<Talker>().error('Failed to trigger SOS from smartwatch', e);
    }
  }

  @override
  Future<void> play() async {
    _handleMediaClick();
    super.play();
  }

  @override
  Future<void> pause() async {
    _handleMediaClick();
    super.pause();
  }

  @override
  Future<void> skipToNext() async {
    _handleMediaClick();
    super.skipToNext();
  }
  
  @override
  Future<void> skipToPrevious() async {
    _handleMediaClick();
    super.skipToPrevious();
  }
}

