import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kawach/core/theme/app_colors.dart';

class SosHistoryPage extends StatefulWidget {
  const SosHistoryPage({super.key});

  @override
  State<SosHistoryPage> createState() => _SosHistoryPageState();
}

class _SosHistoryPageState extends State<SosHistoryPage> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final res = await _client
          .from('sos_alerts')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(50);
      if (mounted) setState(() { _alerts = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'triggered': return AppColors.danger;
      case 'in_progress': return AppColors.warning;
      case 'responded': return AppColors.safe;
      case 'cancelled': return AppColors.textSecondary;
      default: return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'triggered': return Icons.warning_amber_rounded;
      case 'in_progress': return Icons.hourglass_empty;
      case 'responded': return Icons.check_circle_outline;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SOS History', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _alerts.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined, size: 64, color: AppColors.safe),
          ),
          const SizedBox(height: 24),
          const Text('No SOS Events', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your safety record is clean.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (ctx, i) {
        final alert = _alerts[i];
        final status = alert['status'] as String?;
        final triggeredAt = alert['created_at'] as String?;
        final lat = alert['latitude'];
        final lng = alert['longitude'];
        final isMesh = alert['is_offline_mesh_alert'] as bool? ?? false;
        final color = _statusColor(status);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline connector
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 24),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 3),
                      ),
                    ),
                    if (i != _alerts.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.only(top: 4, bottom: 4),
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Event Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                              child: Icon(_statusIcon(status), color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    status?.toUpperCase().replaceAll('_', ' ') ?? 'UNKNOWN',
                                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  if (triggeredAt != null)
                                    Text(
                                      _formatRelativeTime(triggeredAt),
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            if (isMesh)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.meshActive.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: const Text('MESH', style: TextStyle(color: AppColors.meshActive, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        if (lat != null && lng != null) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${double.tryParse(lat.toString())?.toStringAsFixed(5)}, ${double.tryParse(lng.toString())?.toStringAsFixed(5)}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatRelativeTime(String isoString) {
    final date = DateTime.parse(isoString).toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
      if (diff.inMinutes <= 1) return 'Just now';
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24 && now.day == date.day) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (diff.inHours < 48 && now.day - date.day == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('d MMM yyyy • h:mm a').format(date);
    }
  }
}
