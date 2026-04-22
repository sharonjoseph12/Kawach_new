import 'dart:math';

/// Haversine distance between two lat/lng points in metres.
double haversineMeters(
  double lat1, double lng1, double lat2, double lng2,
) {
  const r = 6371000.0; // Earth radius in metres
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _rad(double deg) => deg * pi / 180;
