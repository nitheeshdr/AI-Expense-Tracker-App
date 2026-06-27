import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../design/app_theme.dart';
import '../design/typography.dart';

/// Animated circular progress ring with a track + gradient sweep. Used for the
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
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(
            progress: v,
            track: c.hairline,
            color: ring,
            stroke: stroke,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color color;
  final double stroke;

  _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [color.withValues(alpha: 0.65), color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
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
