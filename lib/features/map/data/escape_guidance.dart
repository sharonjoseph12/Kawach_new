import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';

class SafeDestination {
  final String name;
  final String type;
  final LatLng location;
  final double distance;
  final int safetyScore;

  const SafeDestination({
    required this.name,
    required this.type,
    required this.location,
    required this.distance,
    required this.safetyScore,
  });
}

@LazySingleton()
class EscapeGuidanceService {
  final Dio _dio = Dio();

  Future<List<SafeDestination>> getNearestSafeDestinations(LatLng current) async {
    const double radius = 2000; // 2km
    final query = """
      [out:json];
      (
        node["amenity"="police"](around:$radius,${current.latitude},${current.longitude});
        node["amenity"="hospital"](around:$radius,${current.latitude},${current.longitude});
        node["shop"="mall"](around:1000,${current.latitude},${current.longitude});
        node["railway"="station"](around:$radius,${current.latitude},${current.longitude});
      );
      out body;
    """;

    try {
      final response = await _dio.post(
        'https://overpass-api.de/api/interpreter',
        data: query,
      );

      final elements = response.data['elements'] as List;
      final destinations = elements.map((e) {
        final destLoc = LatLng(e['lat'], e['lon']);
        final distance = Geolocator.distanceBetween(
          current.latitude, current.longitude, destLoc.latitude, destLoc.longitude);
        
        final type = e['tags']['amenity'] ?? e['tags']['shop'] ?? e['tags']['railway'] ?? 'Safe Zone';
        final name = e['tags']['name'] ?? '${type.toUpperCase()} Near You';
        
        return SafeDestination(
          name: name,
          type: type,
          location: destLoc,
          distance: distance.toDouble(),
          safetyScore: _calculateScore(type),
        );
      }).toList();

      destinations.sort((a, b) => a.distance.compareTo(b.distance));
      return destinations.take(4).toList();
    } catch (e) {
      debugPrint('Failed to fetch safe destinations: $e');
      return [];
    }
  }

  int _calculateScore(String type) {
    if (type == 'police') return 100;
    if (type == 'hospital') return 90;
    if (type == 'mall') return 70;
    if (type == 'station') return 60;
    return 50;
  }
}
