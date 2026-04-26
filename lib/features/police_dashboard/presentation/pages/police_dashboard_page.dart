import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/features/police_dashboard/data/police_repository.dart';
import 'package:shimmer/shimmer.dart';

class PoliceDashboardPage extends StatefulWidget {
  const PoliceDashboardPage({super.key});

  @override
  State<PoliceDashboardPage> createState() => _PoliceDashboardPageState();
}

class _PoliceDashboardPageState extends State<PoliceDashboardPage> {
  final _repository = PoliceRepository();
  String? _selectedStationId;
  List<Map<String, dynamic>> _stations = [];

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    final stations = await _repository.getStations();
    setState(() {
      _stations = stations;
      if (_stations.isNotEmpty) {
        _selectedStationId = _stations.first['id'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.security, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'COMMAND CENTER', 
                style: GoogleFonts.orbitron(
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_stations.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStationId,
                  dropdownColor: const Color(0xFF1A1F26),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38, size: 16),
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 10),
                  items: _stations.map((s) => DropdownMenuItem(
                    value: s['id'] as String,
                    child: Text(s['name'] as String),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedStationId = val),
                ),
              ),
            ),
        ],
      ),
      body: _selectedStationId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _repository.getActiveAlerts(_selectedStationId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final alerts = snapshot.data!;
                if (alerts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: AppColors.safe.withValues(alpha: 0.5), size: 64),
                        const SizedBox(height: 16),
                        Text('NO ACTIVE ALERTS', style: GoogleFonts.orbitron(color: Colors.white38, letterSpacing: 2)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    return _ActiveAlertCard(
                      response: alerts[index],
                      onStatusUpdate: (status) => _repository.updateResponseStatus(alerts[index]['id'], status),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ActiveAlertCard extends StatelessWidget {
  final Map<String, dynamic> response;
  final Function(String) onStatusUpdate;

  const _ActiveAlertCard({required this.response, required this.onStatusUpdate});

  @override
  Widget build(BuildContext context) {
    final status = response['response_status'] as String;
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? AppColors.danger.withValues(alpha: 0.5) : Colors.white10,
          width: isPending ? 2 : 1,
        ),
        boxShadow: isPending ? [
          BoxShadow(color: AppColors.danger.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
        ] : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildPulseIndicator(isPending),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VICTIM: ${response['victim_name']}', 
                        style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(response['dispatch_message'] ?? 'Dispatching officers...', 
                        style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _MiniTag(icon: Icons.location_on, label: '${(response['latitude'] as num).toStringAsFixed(4)}, ${(response['longitude'] as num).toStringAsFixed(4)}'),
                          const SizedBox(width: 8),
                          _MiniTag(icon: Icons.bolt, label: (response['trigger_type'] ?? 'manual').toString().toUpperCase()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Assigned at: ${DateTime.parse(response['assigned_at']).toLocal().toString().split('.')[0]}', 
                        style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  label: 'DISPATCH',
                  icon: Icons.local_police,
                  color: AppColors.primary,
                  onPressed: status == 'pending' ? () => onStatusUpdate('dispatched') : null,
                ),
                _ActionButton(
                  label: 'ON SITE',
                  icon: Icons.location_on,
                  color: AppColors.warning,
                  onPressed: status == 'dispatched' ? () => onStatusUpdate('on_site') : null,
                ),
                _ActionButton(
                  label: 'RESOLVE',
                  icon: Icons.check_circle,
                  color: AppColors.safe,
                  onPressed: status == 'on_site' ? () => onStatusUpdate('resolved') : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator(bool isPending) {
    if (!isPending) return const Icon(Icons.warning_amber_rounded, color: AppColors.warning);
    return Shimmer.fromColors(
      baseColor: AppColors.danger,
      highlightColor: Colors.white,
      child: const Icon(Icons.error_outline, color: AppColors.danger, size: 28),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white54),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 8)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'pending': color = AppColors.danger; break;
      case 'dispatched': color = AppColors.primary; break;
      case 'on_site': color = AppColors.warning; break;
      case 'resolved': color = AppColors.safe; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(status.toUpperCase(), style: GoogleFonts.orbitron(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({required this.label, required this.icon, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;
    return InkWell(
      onTap: onPressed,
      child: Opacity(
        opacity: disabled ? 0.3 : 1.0,
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.orbitron(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
