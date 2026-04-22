import 'package:flutter/material.dart';
import 'package:kawach/core/theme/app_colors.dart';

class RiskIndicator extends StatelessWidget {
  final String risk; // 'low', 'normal', 'high'
  const RiskIndicator({super.key, required this.risk});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    
    switch (risk) {
      case 'low':
        color = AppColors.safe;
        label = 'Safe';
        break;
      case 'high':
        color = AppColors.danger;
        label = 'Danger';
        break;
      default:
        color = AppColors.warning;
        label = 'Alert';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
