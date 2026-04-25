import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final _client = Supabase.instance.client;
  Position? _currentPosition;
  bool _loadingLocation = true;
  
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};
  
  final bool _showIncidents = true;
  final bool _showHeatmap = true;
  MapType _currentMapType = MapType.normal;

  static List<Map<String, dynamic>>? _cachedIncidents;
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
        setState(() => _loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() { 
          _currentPosition = pos; 
          _loadingLocation = false; 
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _loadMapData({bool forceRefresh = false}) async {
    final cacheValid = _lastFetch != null && DateTime.now().difference(_lastFetch!).inMinutes < 5;
    if (!forceRefresh && cacheValid && _cachedIncidents != null) {
      _processData(_cachedIncidents!);
      return;
    }
    try {
      final res = await _client
          .from('community_reports')
          .select('latitude, longitude, severity_level, incident_type, description')
          .limit(200);

      final incidents = List<Map<String, dynamic>>.from(res);
      _cachedIncidents = incidents;
      _lastFetch = DateTime.now();
      _processData(incidents);
    } catch (_) {}
  }

  void _processData(List<Map<String, dynamic>> incidents) {
    if (!mounted) return;
    
    final markers = <Marker>{};
    final circles = <Circle>{};

    for (var i = 0; i < incidents.length; i++) {
      final r = incidents[i];
      final lat = double.tryParse(r['latitude'].toString()) ?? 0;
      final lng = double.tryParse(r['longitude'].toString()) ?? 0;
      final severity = r['severity_level'] as int? ?? 3;
      final type = r['incident_type'] as String? ?? 'other';
      
      final pos = LatLng(lat, lng);

      if (_showIncidents) {
        markers.add(
          Marker(
            markerId: MarkerId('incident_$i'),
            position: pos,
            infoWindow: InfoWindow(
              title: type.toUpperCase(),
              snippet: 'Severity: $severity/5',
              onTap: () => _showIncidentDetail(r),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              severity >= 4 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
            ),
          ),
        );
      }

      if (_showHeatmap) {
        Color color;
        double opacity;
        if (severity <= 2) { color = AppColors.safe; opacity = 0.2; }
        else if (severity <= 3) { color = AppColors.warning; opacity = 0.3; }
        else { color = AppColors.danger; opacity = 0.4; }

        circles.add(
          Circle(
            circleId: CircleId('heat_$i'),
            center: pos,
            radius: 200,
            fillColor: color.withValues(alpha: opacity),
            strokeWidth: 0,
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _circles = circles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialPos = _currentPosition != null 
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(12.9716, 77.5946);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Safety Map (Google)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.layers, color: _currentMapType == MapType.satellite ? AppColors.primary : AppColors.textSecondary),
            onPressed: () => setState(() => _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal),
            tooltip: 'Toggle Satellite',
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.primary),
            onPressed: _fetchLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initialPos, zoom: 14),
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: _currentMapType,
            markers: _markers,
            circles: _circles,
            style: _currentMapType == MapType.normal ? _darkMapStyle : null,
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
                  Text('${_markers.length} incidents nearby',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIncidentDetail(Map<String, dynamic> r) {
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
            Text((r['incident_type'] ?? 'OTHER').toString().toUpperCase(), 
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(r['description'] ?? 'No description provided.', style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse('google.navigation:q=${r['latitude']},${r['longitude']}')),
                icon: const Icon(Icons.directions, color: Colors.white),
                label: const Text('Navigate with Google Maps', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#212121"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#181818"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  }
]
''';
}
