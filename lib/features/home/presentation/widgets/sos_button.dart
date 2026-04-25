import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/core/utils/startup_utils.dart';
import 'package:vibration/vibration.dart';

class SOSButton extends StatefulWidget {
  final VoidCallback onTrigger;
  const SOSButton({super.key, required this.onTrigger});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with TickerProviderStateMixin {
  late AnimationController _holdController;
  late AnimationController _gradientController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _triggerSOS();
        }
      });

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _triggerSOS() async {
    HapticFeedback.heavyImpact();
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(
          pattern: [0, 300, 100, 300, 100, 600],
          intensities: [0, 255, 0, 200, 0, 255]);
    }

    final online = await hasConnectivity();
    if (!online && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ Offline: Alerting nearby devices via BLE Mesh.'),
        backgroundColor: AppColors.warning,
      ));
      // Will still call onTrigger so the offline mesh logic runs
    }

    widget.onTrigger();
    _reset();
  }

  void _reset() {
    if (mounted) setState(() => _isHolding = false);
    _holdController.reset();
  }

  @override
  void dispose() {
    _holdController.dispose();
    _gradientController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        HapticFeedback.mediumImpact();
        setState(() => _isHolding = true);
        _holdController.forward();
      },
      onLongPressEnd: (_) => _reset(),
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring (always active)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Container(
                width: 200 + (_pulseAnimation.value * 20),
                height: 200 + (_pulseAnimation.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary
                        .withValues(alpha: 0.3 - (_pulseAnimation.value * 0.2)),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Hold progress ring
            AnimatedBuilder(
              animation: _holdController,
              builder: (_, __) => SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: _holdController.value,
                  strokeWidth: 6,
                  backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            // Core button
            AnimatedBuilder(
              animation: _gradientController,
              builder: (_, __) {
                final t = _gradientController.value;
                return Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.lerp(
                            const Color(0xFFE91E63),
                            const Color(0xFFC2185B),
                            t)!,
                        Color.lerp(
                            const Color(0xFFC2185B),
                            const Color(0xFF880E4F),
                            t)!,
                      ],
                      radius: 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: _isHolding ? 0.7 : 0.4),
                        blurRadius: _isHolding ? 50 : 25,
                        spreadRadius: _isHolding ? 12 : 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SOS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _isHolding ? 'HOLD...' : 'HOLD 2S',
                            key: ValueKey(_isHolding),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

