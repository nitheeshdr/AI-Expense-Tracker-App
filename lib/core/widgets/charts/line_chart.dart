import 'package:flutter/widgets.dart';

import '../../design/app_theme.dart';

/// Smooth, animated area+line chart drawn from scratch. The line draws in
/// progressively (0→1) and the area fades under it. No chart library.
class MiniLineChart extends StatelessWidget {
  final List<double> values;
  final double height;
  final Color? color;

  const MiniLineChart({
    super.key,
    required this.values,
    this.height = 120,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final line = color ?? c.accent;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: _LinePainter(
            values: values,
            progress: t,
            color: line,
            grid: c.hairline,
            labelColor: c.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// Compact money-ish label, e.g. 12500 -> "12.5k", 2_300_000 -> "2.3M".
String compactNum(double v) {
  final a = v.abs();
  if (a >= 1e7) return '${(v / 1e7).toStringAsFixed(1)}Cr';
  if (a >= 1e5) return '${(v / 1e5).toStringAsFixed(1)}L';
  if (a >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final double progress;
  final Color color;
  final Color grid;
  final Color labelColor;

  _LinePainter({
    required this.values,
    required this.progress,
    required this.color,
    required this.grid,
    required this.labelColor,
  });

  void _label(Canvas canvas, String text, Offset at,
      {Color? color, bool right = false, double size = 9}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color ?? labelColor,
              fontSize: size,
              fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = right ? at.dx - tp.width : at.dx;
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    // baseline grid
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pts = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final norm = (values[i] - minV) / range;
      final y = size.height - norm * size.height * 0.86 - size.height * 0.07;
      pts.add(Offset(x, y));
    }

    // build smooth path with catmull-ish control points
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      path.quadraticBezierTo(mid.dx, mid.dy, p1.dx, p1.dy);
    }

    // progressive reveal via path metrics
    final metrics = path.computeMetrics().toList();
    final drawPath = Path();
    for (final m in metrics) {
      drawPath.addPath(m.extractPath(0, m.length * progress), Offset.zero);
    }

    // area fill under the revealed portion
    final revealWidth = size.width * progress;
    final area = Path.from(drawPath)
      ..lineTo(revealWidth, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(area, areaPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(drawPath, linePaint);

    // endpoint dot + value labels
    if (progress > 0.95 && pts.isNotEmpty) {
      canvas.drawCircle(pts.last, 4.5, Paint()..color = color);
      canvas.drawCircle(
          pts.last, 8, Paint()..color = color.withValues(alpha: 0.25));
      // peak label (top-left), baseline (bottom-left), latest value at endpoint
      _label(canvas, compactNum(maxV), const Offset(0, 0));
      _label(canvas, compactNum(minV), Offset(0, size.height - 12));
      final last = values.last;
      _label(canvas, compactNum(last),
          Offset(pts.last.dx - 2, (pts.last.dy - 16).clamp(0, size.height - 12)),
          right: true, color: color, size: 10);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.labelColor != labelColor;
}
