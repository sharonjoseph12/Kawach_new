import 'package:flutter/material.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:kawach/features/diagnostics/system_health_service.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  final _healthService = getIt<SystemHealthService>();
  List<HealthCheck>? _checks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoading = true);
    final results = await _healthService.performFullDiagnostics();
    setState(() {
      _checks = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('System Diagnostics', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _buildContent(),
    );
  }

  Widget _buildContent() {
    final allHealthy = _checks!.every((c) => c.isHealthy);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header Status
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: allHealthy ? AppColors.safe.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: allHealthy ? AppColors.safe : AppColors.danger,
                width: 2,
              )
            ),
            child: Row(
              children: [
                Icon(
                  allHealthy ? Icons.verified_user : Icons.gpp_bad, 
                  color: allHealthy ? AppColors.safe : AppColors.danger,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allHealthy ? 'PROTECTION ACTIVE' : 'VULNERABILITY DETECTED',
                        style: TextStyle(
                          color: allHealthy ? AppColors.safe : AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        allHealthy 
                          ? 'All physical and software modules are armed and operational.'
                          : 'Your phone setup is compromising your safety capabilities. Fix issues below.',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Checks List
          Expanded(
            child: ListView.separated(
              itemCount: _checks!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final check = _checks![index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        check.isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: check.isHealthy ? AppColors.safe : AppColors.warning,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              check.label, 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            const SizedBox(height: 4),
                            Text(
                              check.description,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
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
