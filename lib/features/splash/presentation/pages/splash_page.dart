import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:kawach/core/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _shieldController;
  late AnimationController _textController;
  late AnimationController _taglineController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _shieldScale;
  late Animation<double> _shieldOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Shield assembles from small to full
    _shieldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shieldScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.elasticOut),
    );
    _shieldOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shieldController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    // "KAWACH" text fades in
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Tagline slides up and fades in
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );

    // Continuous pulse behind shield
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Particle burst
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _particleController.forward();
    _shieldController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _pulseController.repeat(reverse: true);
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _taglineController.forward();
    await Future.delayed(const Duration(milliseconds: 1300));
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _shieldController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Deep dark navy
              Color(0xFF1E1030), // Dark purple-navy
              Color(0xFF2D1B3D), // Subtle purple
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Floating particles
            ...List.generate(20, (i) => _FloatingParticle(
              controller: _particleController,
              index: i,
            )),

            // Pulsing glow ring behind shield
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Container(
                width: 180 * _pulseAnimation.value,
                height: 180 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Center column
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shield icon
                AnimatedBuilder(
                  animation: _shieldController,
                  builder: (_, __) => Opacity(
                    opacity: _shieldOpacity.value,
                    child: Transform.scale(
                      scale: _shieldScale.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE91E63),
                              Color(0xFFC2185B),
                              Color(0xFF880E4F),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // "KAWACH" text
                FadeTransition(
                  opacity: _textOpacity,
                  child: Text(
                    'KAWACH',
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineOpacity,
                    child: Text(
                      'Your AI-Powered Safety Shield',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white54,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Bottom version text
            Positioned(
              bottom: 48,
              child: FadeTransition(
                opacity: _taglineOpacity,
                child: Text(
                  'Build for Bangalore 2026',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white24,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingParticle extends StatelessWidget {
  final AnimationController controller;
  final int index;

  const _FloatingParticle({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    final random = Random(index * 42);
    final size = MediaQuery.of(context).size;
    final startX = random.nextDouble() * size.width;
    final startY = random.nextDouble() * size.height;
    final endX = startX + (random.nextDouble() - 0.5) * 150;
    final endY = startY - random.nextDouble() * 200;
    final particleSize = 2.0 + random.nextDouble() * 4;
    final delay = random.nextDouble() * 0.4;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = ((controller.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        final x = startX + (endX - startX) * t;
        final y = startY + (endY - startY) * t;
        final opacity = (1 - t) * 0.6;

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: particleSize,
              height: particleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index % 3 == 0
                    ? AppColors.primary
                    : index % 3 == 1
                        ? Colors.pinkAccent
                        : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
