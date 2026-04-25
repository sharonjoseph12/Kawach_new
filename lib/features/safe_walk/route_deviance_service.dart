import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:kawach/app/di/injection.dart';

@LazySingleton()
class RouteDevianceService {
  final Dio _dio;
  List<LatLng> _currentRoute = [];
  bool _isTracking = false;

  RouteDevianceService(this._dio);

  Future<void> startTrackingCommute(LatLng origin, LatLng destination) async {
    _isTracking = true;
    _currentRoute = await _fetchRoute(origin, destination);
    getIt<Talker>().info('RouteDevianceService: Commute tracking started. Route has ${_currentRoute.length} points.');
  }

  void stopTracking() {
    _isTracking = false;
    _currentRoute.clear();
  }

  bool get isTracking => _isTracking;

  /// Returns true if the user has deviated from the route by more than threshold (meters)
  bool isDeviating(LatLng currentLocation, {double thresholdMeters = 500.0}) {
    if (!_isTracking || _currentRoute.isEmpty) return false;

    double minDistance = double.infinity;

    for (int i = 0; i < _currentRoute.length - 1; i++) {
      final p1 = _currentRoute[i];
      final p2 = _currentRoute[i + 1];
      final dist = _distanceToSegment(currentLocation, p1, p2);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    // If polyline points are sparse, just checking nearest point is a fallback
    for (final point in _currentRoute) {
      final dist = Geolocator.distanceBetween(
        currentLocation.latitude, currentLocation.longitude,
        point.latitude, point.longitude);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    return minDistance > thresholdMeters;
  }

  Future<List<LatLng>> _fetchRoute(LatLng origin, LatLng destination) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    
    // GDG Hackathon Mock/Fallback if no API key is provided
    if (apiKey == null || apiKey.isEmpty || apiKey == 'placeholder') {
      getIt<Talker>().warning('RouteDevianceService: Using simulated straight-line route due to missing API key.');
      return _generateSimulatedRoute(origin, destination);
    }

    try {
      final response = await _dio.post(
        'https://routes.googleapis.com/directions/v2:computeRoutes',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
        }),
        data: {
          "origin": {
            "location": {"latLng": {"latitude": origin.latitude, "longitude": origin.longitude}}
          },
          "destination": {
            "location": {"latLng": {"latitude": destination.latitude, "longitude": destination.longitude}}
          },
          "travelMode": "DRIVE",
        },
      );

      final encodedPolyline = response.data['routes'][0]['polyline']['encodedPolyline'];
      return _decodePolyline(encodedPolyline);
    } catch (e) {
      getIt<Talker>().error('RouteDevianceService: Failed to fetch route from Google API. Using fallback.', e);
      return _generateSimulatedRoute(origin, destination);
    }
  }

  // Basic equirectangular approximation for point-to-line-segment distance (in meters)
  double _distanceToSegment(LatLng p, LatLng v, LatLng w) {
    const R = 6371000; // Earth radius in meters
    final pLat = p.latitude * math.pi / 180;
    final pLng = p.longitude * math.pi / 180;
    final vLat = v.latitude * math.pi / 180;
    final vLng = v.longitude * math.pi / 180;
    final wLat = w.latitude * math.pi / 180;
    final wLng = w.longitude * math.pi / 180;

    final l2 = math.pow(wLat - vLat, 2) + math.pow((wLng - vLng) * math.cos(vLat), 2);
    if (l2 == 0) {
      return R * math.sqrt(math.pow(pLat - vLat, 2) + math.pow((pLng - vLng) * math.cos(vLat), 2));
    }
    
    var t = ((pLat - vLat) * (wLat - vLat) + (pLng - vLng) * math.cos(vLat) * (wLng - vLng) * math.cos(vLat)) / l2;
    t = math.max(0, math.min(1, t));
    
    final projLat = vLat + t * (wLat - vLat);
    final projLng = vLng + t * (wLng - vLng);
    
    return R * math.sqrt(math.pow(pLat - projLat, 2) + math.pow((pLng - projLng) * math.cos(projLat), 2));
  }

  List<LatLng> _generateSimulatedRoute(LatLng origin, LatLng destination) {
    // Generate a simple straight line with 10 points for hackathon demo
    List<LatLng> route = [];
    for (int i = 0; i <= 10; i++) {
      final t = i / 10.0;
      final lat = origin.latitude + (destination.latitude - origin.latitude) * t;
      final lng = origin.longitude + (destination.longitude - origin.longitude) * t;
      route.add(LatLng(lat, lng));
    }
    return route;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return poly;
  }
}
