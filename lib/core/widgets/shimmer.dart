import 'package:flutter/widgets.dart';

import '../design/app_theme.dart';
import '../design/spacing.dart';

/// A shimmering placeholder block for skeleton loading states.
class Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const Shimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppRadii.sm,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final base = c.surfaceElevated;
    final highlight = c.isDark
        ? const Color(0x22FFFFFF)
        : const Color(0x11000000);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - _ctrl.value * 2, 0),
              end: Alignment(1 - _ctrl.value * 2, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton list-row matching the transaction row layout.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Shimmer(width: 44, height: 44, radius: 14),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Shimmer(width: 140, height: 13),
                SizedBox(height: 8),
                Shimmer(width: 80, height: 11),
              ],
            ),
          ),
          const Shimmer(width: 60, height: 14),
        ],
      ),
    );
  }
}
