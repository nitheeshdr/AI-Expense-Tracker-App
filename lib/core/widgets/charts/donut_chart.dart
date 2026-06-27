import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../data/categories.dart';
import '../../data/models.dart';
import '../../design/app_theme.dart';

/// Animated donut chart of category spending with a center total. Slices sweep
/// in together. Colors come from the category catalog.
class CategoryDonut extends StatelessWidget {
  final List<CategoryTotal> data;
  final double size;
  final Widget? center;

  const CategoryDonut({
    super.key,
    required this.data,
    this.size = 160,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 950),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: _DonutPainter(
            data: data,
            progress: t,
            track: c.hairline,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<CategoryTotal> data;
  final double progress;
  final Color track;

  _DonutPainter({
    required this.data,
    required this.progress,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const stroke = 18.0;
    final rect =
        Rect.fromCircle(center: center, radius: radius - stroke / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius - stroke / 2, trackPaint);

    final total = data.fold(0.0, (a, b) => a + b.total);
    if (total <= 0) return;

    var start = -math.pi / 2;
    const gap = 0.04;
    for (final slice in data) {
      final sweep = (slice.total / total) * (2 * math.pi) * progress;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = Categories.of(slice.category).color;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(sweep - gap, 0.001),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.data != data;
}
