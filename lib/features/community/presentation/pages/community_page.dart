import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kawach/core/theme/app_colors.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tabs;
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  DateTime? _lastReportTime; // Cooldown tracker

  static const _incidentLabels = {
    'harassment': ('Harassment', Icons.warning_amber, AppColors.warning),
    'assault': ('Assault', Icons.personal_injury, AppColors.danger),
    'theft': ('Theft', Icons.money_off, AppColors.secondary),
    'other': ('Other', Icons.report_gmailerrorred, AppColors.textSecondary),
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final res = await _client
          .from('community_reports')
          .select()
          .order('reported_at', ascending: false)
          .limit(100);
      if (mounted) setState(() { _reports = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitReport({
    required String incidentType,
    required String description,
    required int severity,
    required bool anonymous,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    // 60-second cooldown to prevent duplicate/spam reports
    if (_lastReportTime != null &&
        DateTime.now().difference(_lastReportTime!).inSeconds < 60) {
      final remaining = 60 - DateTime.now().difference(_lastReportTime!).inSeconds;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please wait ${remaining}s before submitting another report.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    await _client.from('community_reports').insert({
      'user_id': uid,
      'incident_type': incidentType,
      'description': description,
      'severity_level': severity,
      'is_anonymous': anonymous,
      'latitude': pos?.latitude ?? 12.9716,
      'longitude': pos?.longitude ?? 77.5946,
    });
    _lastReportTime = DateTime.now();
    await _load();
  }

  void _showReportSheet() {
    String selectedType = 'harassment';
    int severity = 3;
    bool anonymous = true;
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report Incident', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Help your community stay safe.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              // Type chips
              Wrap(
                spacing: 8,
                children: _incidentLabels.entries.map((e) {
                  final (label, icon, color) = e.value;
                  final selected = selectedType == e.key;
                  return FilterChip(
                    selected: selected,
                    avatar: Icon(icon, size: 16, color: selected ? color : AppColors.textSecondary),
                    label: Text(label, style: TextStyle(color: selected ? color : AppColors.textSecondary, fontSize: 12)),
                    backgroundColor: AppColors.card,
                    selectedColor: color.withValues(alpha: 0.12),
                    side: BorderSide(color: selected ? color : Colors.transparent),
                    checkmarkColor: color,
                    onSelected: (_) => setModal(() => selectedType = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Describe what happened (optional)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Severity:', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: severity.toDouble(),
                      min: 1, max: 5, divisions: 4,
                      activeColor: AppColors.danger,
                      label: '$severity',
                      onChanged: (v) => setModal(() => severity = v.round()),
                    ),
                  ),
                  Text('$severity/5', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              SwitchListTile(
                value: anonymous,
                onChanged: (v) => setModal(() => anonymous = v),
                title: const Text('Submit anonymously', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                activeTrackColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  await _submitReport(
                    incidentType: selectedType,
                    description: descCtrl.text.trim(),
                    severity: severity,
                    anonymous: anonymous,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Incident reported. Thank you for helping the community.'),
                      backgroundColor: AppColors.safe,
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community Safety', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _load)],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [Tab(text: 'Recent Reports'), Tab(text: 'Stats')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportSheet,
        backgroundColor: AppColors.danger,
        icon: const Icon(Icons.report, color: Colors.white),
        label: const Text('Report Incident', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildReportsList(),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No reports yet', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('Be the first to report an incident.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final r = _reports[i];
        final type = r['incident_type'] as String? ?? 'other';
        final (label, icon, color) = _incidentLabels[type] ?? ('Other', Icons.report_gmailerrorred, AppColors.textSecondary);
        final severity = r['severity_level'] as int? ?? 1;
        final anon = r['is_anonymous'] as bool? ?? true;
        final desc = r['description'] as String?;
        final lat = double.tryParse(r['latitude'].toString());
        final lng = double.tryParse(r['longitude'].toString());

        return Container(
          padding: const EdgeInsets.all(14),
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
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        Text(anon ? 'Anonymous report' : 'Community member',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  // Severity dots
                  Row(
                    children: List.generate(5, (j) => Container(
                      margin: const EdgeInsets.only(left: 3),
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: j < severity ? color : AppColors.textSecondary.withValues(alpha: 0.2),
                      ),
                    )),
                  ),
                ],
              ),
              if (desc != null && desc.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
              ],
              if (lat != null && lng != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStats() {
    final total = _reports.length;
    final byType = <String, int>{};
    for (final r in _reports) {
      final t = r['incident_type'] as String? ?? 'other';
      byType[t] = (byType[t] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(label: 'Total Reports', value: total.toString(), icon: Icons.bar_chart, color: AppColors.primary),
        const SizedBox(height: 12),
        ..._incidentLabels.entries.map((e) {
          final (label, icon, color) = e.value;
          final count = byType[e.key] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StatCard(label: label, value: count.toString(), icon: icon, color: color),
          );
        }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)),
        ],
      ),
    );
  }
}
