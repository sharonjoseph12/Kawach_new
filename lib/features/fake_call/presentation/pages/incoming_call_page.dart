import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:kawach/core/theme/app_colors.dart';
// Note: audioplayers is in pubspec, but for strictness in this artifact 
// without needing assets, we'll rely on aggressive vibration pattern.

class IncomingCallPage extends StatefulWidget {
  final String callerName;
  const IncomingCallPage({super.key, required this.callerName});

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  Timer? _vibrateTimer;
  bool _isAnswered = false;
  int _secondsElapsed = 0;
  Timer? _callTimer;

  @override
  void initState() {
    super.initState();
    _startRinging();
  }

  Future<void> _startRinging() async {
    // Vibrate: Ring pattern
    if (await Vibration.hasVibrator()) {
      _vibrateTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
        Vibration.vibrate(pattern: [0, 1000, 1000]);
      });
    }
    // Timeout call if not answered in 60s
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted && !_isAnswered) {
        _endCall();
      }
    });
  }

  void _answerCall() {
    _vibrateTimer?.cancel();
    Vibration.cancel();
    setState(() {
      _isAnswered = true;
    });

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  void _endCall() {
    _vibrateTimer?.cancel();
    _callTimer?.cancel();
    Vibration.cancel();
    if (mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _vibrateTimer?.cancel();
    _callTimer?.cancel();
    Vibration.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const SizedBox(height: 60),
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isAnswered ? _formatTime(_secondsElapsed) : 'mobile',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 60, left: 40, right: 40),
              child: _isAnswered 
                ? _buildActiveCallControls() 
                : _buildIncomingControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildButton(
          color: const Color(0xFFFF3B30),
          icon: Icons.call_end,
          label: 'Decline',
          onTap: _endCall,
        ),
        _buildButton(
          color: const Color(0xFF34C759),
          icon: Icons.call,
          label: 'Accept',
          onTap: _answerCall,
        ),
      ],
    );
  }

  Widget _buildActiveCallControls() {
    return Column(
      children: [
        // Fake grid controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildGridIcon(Icons.mic_off, 'mute'),
            _buildGridIcon(Icons.dialpad, 'keypad'),
            _buildGridIcon(Icons.volume_up, 'speaker'),
          ],
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
              color: const Color(0xFFFF3B30),
              icon: Icons.call_end,
              label: '',
              onTap: _endCall,
              size: 75,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildButton({
    required Color color, 
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    double size = 70,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.5),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        ]
      ],
    );
  }

  Widget _buildGridIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }
}

