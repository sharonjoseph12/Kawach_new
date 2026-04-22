import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:kawach/core/theme/app_colors.dart';

class SafetyHeatmapLayer extends StatelessWidget {
  final List<SafetyPoint> safetyPoints;
  
  const SafetyHeatmapLayer({super.key, required this.safetyPoints});

  @override
  Widget build(BuildContext context) {
    return CircleLayer(
      circles: safetyPoints.map((point) {
        Color color;
        double opacity;
        
        if (point.score > 70) {
          color = AppColors.safe;
          opacity = 0.2;
        } else if (point.score > 40) {
          color = AppColors.warning;
          opacity = 0.3;
        } else {
          color = AppColors.danger;
          opacity = 0.4;
        }

        return CircleMarker(
          point: point.location,
          color: color.withValues(alpha: opacity),
          borderStrokeWidth: 0,
          useRadiusInMeter: true,
          radius: 200, // Adaptive radius
        );
      }).toList(),
    );
  }
}

class SafetyPoint {
  final LatLng location;
  final double score;
  const SafetyPoint({required this.location, required this.score});
}
