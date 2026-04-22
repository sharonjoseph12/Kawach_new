import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/features/map/presentation/widgets/safety_heatmap_layer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapController = MapController();
  final _client = Supabase.instance.client;
  Position? _currentPosition;
  bool _loadingLocation = true;
  List<SafetyPoint> _safetyPoints = [];
  List<Map<String, dynamic>> _incidents = [];
  bool _showIncidents = true;
  bool _showHeatmap = true;

  // 5-minute in-memory cache to avoid repeated Supabase scans on every open
  static List<Map<String, dynamic>>? _cachedIncidents;
  static List<SafetyPoint>? _cachedPoints;
  static DateTime? _lastFetch;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _loadMapData();
  }

  Future<void> _fetchLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _loadingLocation = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permission denied. Enable it in app settings.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ));
        }
        return;
      }
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() { _currentPosition = pos; _loadingLocation = false; });
        _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _loadMapData({bool forceRefresh = false}) async {
    // Use cache if fresh (< 5 minutes old) and not forcing refresh
    final cacheValid = _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 5;
    if (!forceRefresh && cacheValid && _cachedIncidents != null) {
      if (mounted) setState(() { _incidents = _cachedIncidents!; _safetyPoints = _cachedPoints!; });
      return;
    }
    try {
      // Load community incidents
      final res = await _client
          .from('community_reports')
          .select('latitude, longitude, severity_level, incident_type, reported_at')
          .order('reported_at', ascending: false)
          .limit(200);

      final incidents = List<Map<String, dynamic>>.from(res);

      // Convert incidents to safety points (invert severity for safety score)
      final points = incidents.map((r) {
        final lat = double.tryParse(r['latitude'].toString()) ?? 0;
        final lng = double.tryParse(r['longitude'].toString()) ?? 0;
        final severity = r['severity_level'] as int? ?? 3;
        // severity 1-5 → safety score 80-20
        final safetyScore = ((6 - severity) / 5.0 * 80).round();
        return SafetyPoint(location: LatLng(lat, lng), score: safetyScore.toDouble());
      }).toList();

      // Update cache
      _cachedIncidents = incidents;
      _cachedPoints = points;
      _lastFetch = DateTime.now();

      if (mounted) setState(() { _incidents = incidents; _safetyPoints = points; });
    } catch (_) {}
  }

  Color _incidentColor(String? type, int? severity) {
    final s = severity ?? 3;
    if (s >= 4) return AppColors.danger;
    if (s >= 3) return AppColors.warning;
    return AppColors.secondary;
  }

  IconData _incidentIcon(String? type) {
    switch (type) {
      case 'assault': return Icons.personal_injury;
      case 'harassment': return Icons.warning_amber;
      case 'theft': return Icons.money_off;
      default: return Icons.report;
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(12.9716, 77.5946);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Safety Map',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.warning_amber_rounded,
                color: _showIncidents ? AppColors.danger : AppColors.textSecondary),
            tooltip: 'Toggle Incidents',
            onPressed: () => setState(() => _showIncidents = !_showIncidents),
          ),
          IconButton(
            icon: Icon(Icons.layers,
                color: _showHeatmap ? AppColors.primary : AppColors.textSecondary),
            tooltip: 'Toggle Heatmap',
            onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.primary),
            onPressed: _fetchLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.kawach.app',
              ),
              if (_showHeatmap && _safetyPoints.isNotEmpty)
                SafetyHeatmapLayer(safetyPoints: _safetyPoints),
              // Community incident pins
              if (_showIncidents)
                MarkerLayer(
                  markers: [
                    for (final r in _incidents)
                      if (double.tryParse(r['latitude'].toString()) != null && double.tryParse(r['longitude'].toString()) != null)
                        Marker(
                          point: LatLng(double.parse(r['latitude'].toString()), double.parse(r['longitude'].toString())),
                          width: 32, height: 32,
                          child: GestureDetector(
                            onTap: () => _showIncidentDetail(r),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _incidentColor(r['incident_type'] as String?, r['severity_level'] as int?),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(color: _incidentColor(r['incident_type'] as String?, r['severity_level'] as int?).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1),
                                ],
                              ),
                              child: Icon(_incidentIcon(r['incident_type'] as String?), color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                    // Current user marker
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        width: 40, height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.9),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 3),
                            ],
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (_loadingLocation)
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          // Stats chip
          Positioned(
            top: 12, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.danger, size: 14),
                  const SizedBox(width: 6),
                  Text('${_incidents.length} incidents nearby',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          // Legend
          Positioned(
            bottom: 24, left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendItem(color: Color(0xFF00C853), label: 'Safe (>70)'),
                  SizedBox(height: 6),
                  _LegendItem(color: Color(0xFFFFB300), label: 'Moderate (40–70)'),
                  SizedBox(height: 6),
                  _LegendItem(color: Color(0xFFD50000), label: 'Danger (<40)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIncidentDetail(Map<String, dynamic> r) {
    final type = r['incident_type'] as String? ?? 'other';
    final severity = r['severity_level'] as int? ?? 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type.toUpperCase(), style: TextStyle(color: _incidentColor(type, severity), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Severity: ', style: TextStyle(color: AppColors.textSecondary)),
              Row(children: List.generate(5, (i) => Icon(Icons.circle, size: 10, color: i < severity ? AppColors.danger : AppColors.card))),
            ]),
            const SizedBox(height: 8),
            const Text('Anonymous community report', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
      ],
    );
  }
}
