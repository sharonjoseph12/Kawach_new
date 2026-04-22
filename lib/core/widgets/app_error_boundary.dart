import 'package:flutter/material.dart';
import 'package:kawach/core/theme/app_colors.dart';

/// Wraps the entire app to catch uncaught Flutter framework errors
/// and show a premium error screen instead of a blank/red crash.
class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  const AppErrorBoundary({super.key, required this.child});

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Capture Flutter framework errors
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      original?.call(details);
      if (mounted) setState(() => _error = details.exception);
    };
  }

  void _retry() => setState(() => _error = null);

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, size: 64, color: AppColors.danger),
                  ),
                  const SizedBox(height: 32),
                  const Text('Something went wrong',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  const Text(
                    'Kawach encountered an unexpected error. Your safety data is preserved.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(200, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Restart App', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
