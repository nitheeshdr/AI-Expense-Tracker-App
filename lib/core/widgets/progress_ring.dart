import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import '../design/typography.dart';

/// Animated circular progress ring built on the native
/// [CircularProgressIndicator] (flat color, no gradient). Used for the
/// financial health score, budget rings and savings goals.
class ProgressRing extends StatelessWidget {
  final double progress; // 0..1
  final double size;
  final double stroke;
  final Color? color;
  final Widget? center;
  final bool animate;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 72,
    this.stroke = 8,
    this.color,
    this.center,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final ring = color ?? c.accent;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0, 1)),
        duration: animate ? const Duration(milliseconds: 900) : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Stack(
          alignment: Alignment.center,
          children: [
            // CircularProgressIndicator defaults to its own preferred size
            // (~36px) when given loose constraints inside a Stack, ignoring
            // the requested `size` — Positioned.fill forces it to the exact
            // SizedBox bounds instead.
            Positioned.fill(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: stroke,
                strokeCap: StrokeCap.round,
                backgroundColor: c.hairline,
                color: ring,
              ),
            ),
            ?center,
          ],
        ),
      ),
    );
  }
}

/// Convenience: a health/score ring with a big number in the middle.
class ScoreRing extends StatelessWidget {
  final int score; // 0..100
  final double size;
  final Color color;
  const ScoreRing({
    super.key,
    required this.score,
    required this.color,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ProgressRing(
      progress: score / 100,
      size: size,
      stroke: 9,
      color: color,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$score',
              style: AppType.h1.copyWith(color: c.textPrimary, fontSize: 28)),
          Text('SCORE',
              style: AppType.caption.copyWith(color: c.textTertiary)),
        ],
      ),
    );
  }
}
