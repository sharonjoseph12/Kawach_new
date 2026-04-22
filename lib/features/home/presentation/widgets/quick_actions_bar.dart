import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kawach/core/theme/app_colors.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          icon: Icons.directions_walk_rounded,
          label: 'Safe Walk',
          color: AppColors.safe,
          onTap: () => context.push('/safe-walk'),
        ),
        _ActionButton(
          icon: Icons.phone_in_talk_rounded,
          label: 'Fake Call',
          color: const Color(0xFF7C4DFF),
          onTap: () => context.push('/fake-call'),
        ),
        _ActionButton(
          icon: Icons.map_rounded,
          label: 'Heatmap',
          color: AppColors.warning,
          onTap: () => context.push('/map'),
        ),
        _ActionButton(
          icon: Icons.smart_toy_rounded,
          label: 'AI Chat',
          color: AppColors.primary,
          onTap: () => context.push('/guardian-ai'),
        ),
        _ActionButton(
          icon: Icons.people_alt_rounded,
          label: 'Community',
          color: AppColors.danger,
          onTap: () => context.push('/community'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.color.withValues(alpha: 0.3), width: 1),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
