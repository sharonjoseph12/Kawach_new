import 'package:flutter/material.dart';
import 'package:kawach/core/theme/app_colors.dart';

/// Bottom sheet that checks route safety before the user starts walking.
/// Uses the heatmap data via Supabase to scan for risk zones along the route.
class RouteSafetySheet extends StatefulWidget {
  const RouteSafetySheet({super.key});

  @override
  State<RouteSafetySheet> createState() => _RouteSafetySheetState();
}

class _RouteSafetySheetState extends State<RouteSafetySheet> {
  final _destController = TextEditingController();
  bool _isChecking = false;
  _SafetyCheckResult? _result;

  @override
  void dispose() {
    _destController.dispose();
    super.dispose();
  }

  Future<void> _checkRoute() async {
    if (_destController.text.isEmpty) return;
    setState(() { _isChecking = true; _result = null; });

    // Simulate network delay for now — replace with actual compute-safety-scores call
    await Future.delayed(const Duration(seconds: 2));

    // to-do: Geocode destination → get lat/lng
    // Interpolate 10 waypoints between current position and destination
    // Call compute-safety-scores edge function for each waypoint
    // Compute overall risk score

    setState(() {
      _isChecking = false;
      _result = _SafetyCheckResult(
        destination: _destController.text,
        riskZoneCount: 2,
        overallScore: 38,
        recommendation: 'Consider using the main road via NH-48. Avoids 2 flagged zones.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A0A10),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          const Text('Route Safety Check', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Enter your destination to scan for risk zones on the way.', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: _destController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Where are you going?',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.place, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isChecking ? null : _checkRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isChecking
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Check Route', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result!.overallScore < 50 ? AppColors.danger.withValues(alpha: 0.1) : AppColors.safe.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _result!.overallScore < 50 ? AppColors.danger.withValues(alpha: 0.3) : AppColors.safe.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(
                      _result!.riskZoneCount > 0 ? Icons.warning_amber_rounded : Icons.verified_user,
                      color: _result!.overallScore < 50 ? AppColors.danger : AppColors.safe,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_result!.riskZoneCount} risk zone${_result!.riskZoneCount == 1 ? '' : 's'} found',
                      style: TextStyle(
                        color: _result!.overallScore < 50 ? AppColors.danger : AppColors.safe,
                        fontWeight: FontWeight.bold, fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text('Score: ${_result!.overallScore}/100', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ]),
                  const SizedBox(height: 10),
                  Text(_result!.recommendation, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SafetyCheckResult {
  final String destination;
  final int riskZoneCount;
  final int overallScore;
  final String recommendation;

  _SafetyCheckResult({
    required this.destination,
    required this.riskZoneCount,
    required this.overallScore,
    required this.recommendation,
  });
}

/// Show this from any page via:
/// showModalBottomSheet(context: context, builder: (_) => const RouteSafetySheet());
