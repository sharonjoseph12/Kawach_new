import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kawach/core/theme/app_colors.dart';

class FakeCallIncomingPage extends StatefulWidget {
  final String callerName;
  const FakeCallIncomingPage({super.key, required this.callerName});

  @override
  State<FakeCallIncomingPage> createState() => _FakeCallIncomingPageState();
}

class _FakeCallIncomingPageState extends State<FakeCallIncomingPage> {
  bool _isAnswered = false;
  int _callDurationSeconds = 0;
  Timer? _callTimer;

  // Simulate ringing timer so that if they don't answer in 30s it "misses"
  Timer? _ringTimer;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _ringTimer = Timer(const Duration(seconds: 40), () {
      if (!_isAnswered && mounted) {
        context.pop();
      }
    });

    _startRingingVibration();
  }

  void _startRingingVibration() async {
    if (await Vibration.hasVibrator()) {
      if (await Vibration.hasCustomVibrationsSupport()) {
        // pattern: wait, vibrate, wait, vibrate...
        Vibration.vibrate(pattern: [0, 1000, 1000, 1000, 1000, 1000, 1000, 1000], intensities: [0, 255, 0, 255, 0, 255, 0, 255]);
      } else {
        Vibration.vibrate();
      }
    }
  }

  void _answerCall() async {
    Vibration.cancel();
    _ringTimer?.cancel();
    setState(() => _isAnswered = true);
    
    // Start duration timer
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDurationSeconds++);
    });
    
    // Play Deterrent Audio
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(0.9);
    await _flutterTts.setSpeechRate(0.5);
    
    await Future.delayed(const Duration(seconds: 1));
    await _flutterTts.speak("Hello, this is the Bangalore Police Control Room. We have detected an anomaly and route deviation from your device. Are you safe? Officers are currently en route to your live GPS location. Please stay on the line.");
  }

  void _declineCall() {
    Vibration.cancel();
    _flutterTts.stop();
    context.pop();
  }

  @override
  void dispose() {
    Vibration.cancel();
    _flutterTts.stop();
    _callTimer?.cancel();
    _ringTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E), // Native iOS dark gray
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Spacer(flex: 1),
            // Caller Info
            Column(
              children: [
                Text(
                  _isAnswered ? _formatDuration(_callDurationSeconds) : 'mobile',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.callerName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            
            const Spacer(flex: 2),

            // Call Actions Grid (Mute, Keypad, Audio, etc)
            if (_isAnswered)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CallActionBtn(icon: Icons.mic_off_outlined, label: 'mute'),
                        _CallActionBtn(icon: Icons.dialpad, label: 'keypad'),
                        _CallActionBtn(icon: Icons.volume_up_outlined, label: 'audio'),
                      ],
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CallActionBtn(icon: Icons.add_call, label: 'add call'),
                        _CallActionBtn(icon: Icons.video_call_outlined, label: 'FaceTime'),
                        _CallActionBtn(icon: Icons.person_outline, label: 'contacts'),
                      ],
                    ),
                  ],
                ),
              ),
            
            const Spacer(flex: 2),

            // Bottom Buttons (Accept / Decline)
            Padding(
              padding: const EdgeInsets.only(bottom: 60, left: 40, right: 40),
              child: _isAnswered
                  ? GestureDetector(
                      onTap: _declineCall,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _declineCall,
                              child: Container(
                                width: 76, height: 76,
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('Decline', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _answerCall,
                              child: Container(
                                width: 76, height: 76,
                                decoration: const BoxDecoration(
                                  color: AppColors.safe,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.call, color: Colors.white, size: 36),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('Accept', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CallActionBtn({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

