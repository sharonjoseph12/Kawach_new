import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:kawach/core/theme/app_colors.dart';


class FakeCallPage extends StatefulWidget {
  const FakeCallPage({super.key});

  @override
  State<FakeCallPage> createState() => _FakeCallPageState();
}

class _FakeCallPageState extends State<FakeCallPage> {
  String _callerName = 'Mom';
  int _delaySeconds = 10;
  bool _isScheduled = false;
  Timer? _timer;

  void _scheduleCall() {
    setState(() => _isScheduled = true);
    
    // In a real production app, we'd schedule a local notification
    // to bring the app to foreground if backgrounded.
    // For this prototype/MVP, we use a simple timer.
    _timer = Timer(Duration(seconds: _delaySeconds), () async {
      if (mounted) {
        setState(() => _isScheduled = false);
        
        // Trigger realistic phone ringing vibration pattern
        if (await Vibration.hasVibrator() ?? false) {
          if (await Vibration.hasCustomVibrationsSupport() ?? false) {
            Vibration.vibrate(pattern: [0, 1000, 1000, 1000, 1000, 1000], intensities: [0, 255, 0, 255, 0, 255]);
          } else {
            Vibration.vibrate();
          }
        }

        if (mounted) {
          context.push('/fake-call/incoming', extra: _callerName);
        }
      }
    });
  }

  void _cancelScheduledCall() {
    _timer?.cancel();
    setState(() => _isScheduled = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fake Call Delay', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Schedule a realistic incoming phone call to give you a plausible excuse to safely leave an uncomfortable situation.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            
            // Caller Name Input
            TextField(
              decoration: InputDecoration(
                labelText: 'Caller Name',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.card,
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (val) => _callerName = val.isEmpty ? 'Mom' : val,
            ),
            const SizedBox(height: 24),
            
            // Delay Slider
            // ignore: prefer_const_constructors
            Text(
              'Delay: $_delaySeconds seconds',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            Slider(
              value: _delaySeconds.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              activeColor: AppColors.primary,
              onChanged: _isScheduled ? null : (val) {
                setState(() => _delaySeconds = val.toInt());
              },
            ),
            
            const Spacer(),
            
            _isScheduled
              ? ElevatedButton(
                  onPressed: _cancelScheduledCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: const Text('Cancel Scheduled Call', 
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                )
              : ElevatedButton(
                  onPressed: _scheduleCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Schedule Call', 
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
          ],
        ),
      ),
    );
  }
}
