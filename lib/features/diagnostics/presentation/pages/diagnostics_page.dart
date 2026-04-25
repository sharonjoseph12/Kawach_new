import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:kawach/features/diagnostics/system_health_service.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> with SingleTickerProviderStateMixin {
  final _healthService = getIt<SystemHealthService>();
  List<HealthCheck>? _checks;
  bool _isLoading = true;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _runDiagnostics();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoading = true);
    final results = await _healthService.performFullDiagnostics();
    setState(() {
      _checks = results;
      _isLoading = false;
    });
    _scanController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('System Diagnostics', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _scanController.repeat();
              _runDiagnostics();
            },
          ),
        ],
      ),
      body: _isLoading 
        ? _buildScanningUI()
        : _buildContent(),
    );
  }

  Widget _buildScanningUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _scanController,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: const Icon(Icons.radar, color: AppColors.primary, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'SCANNING SYSTEMS...',
            style: GoogleFonts.orbitron(
              color: AppColors.primary,
              fontSize: 14,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final healthyCount = _checks!.where((c) => c.isHealthy).length;
    final totalCount = _checks!.length;
    final allHealthy = healthyCount == totalCount;
    final score = ((healthyCount / totalCount) * 100).round();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Score Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: allHealthy 
                  ? [AppColors.safe.withValues(alpha: 0.15), AppColors.safe.withValues(alpha: 0.05)]
                  : [AppColors.danger.withValues(alpha: 0.15), AppColors.danger.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: allHealthy ? AppColors.safe.withValues(alpha: 0.3) : AppColors.danger.withValues(alpha: 0.3),
                width: 1,
              )
            ),
            child: Row(
              children: [
                // Score circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: allHealthy ? AppColors.safe : AppColors.danger,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$score%',
                      style: GoogleFonts.orbitron(
                        color: allHealthy ? AppColors.safe : AppColors.danger,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allHealthy ? 'PROTECTION ACTIVE' : 'ISSUES DETECTED',
                        style: GoogleFonts.orbitron(
                          color: allHealthy ? AppColors.safe : AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$healthyCount of $totalCount systems operational',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  allHealthy ? Icons.verified_user : Icons.gpp_bad, 
                  color: allHealthy ? AppColors.safe : AppColors.danger,
                  size: 36,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Checks List
          Expanded(
            child: ListView.separated(
              itemCount: _checks!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final check = _checks![index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: check.isHealthy 
                        ? AppColors.safe.withValues(alpha: 0.15) 
                        : AppColors.danger.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (check.isHealthy ? AppColors.safe : AppColors.danger).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          check.isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: check.isHealthy ? AppColors.safe : AppColors.danger,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              check.label, 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                            ),
                            const SizedBox(height: 2),
                            Text(
                              check.description,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (check.detail != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (check.isHealthy ? AppColors.safe : AppColors.danger).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            check.detail!,
                            style: TextStyle(
                              color: check.isHealthy ? AppColors.safe : AppColors.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
