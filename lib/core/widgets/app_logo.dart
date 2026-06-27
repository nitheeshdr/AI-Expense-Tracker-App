import 'package:flutter/material.dart';

/// The app's monochrome logo mark — a rounded square framing ascending bars and
/// a trend line. Painted in [color] so it works as a white or black logo.
/// Mirrors assets/logo/logo_white.svg and logo_black.svg.
class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  const AppLogo({super.key, this.size = 64, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(color ?? Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  _LogoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 256.0;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24 * s, 24 * s, 208 * s, 208 * s),
        Radius.circular(52 * s),
      ),
      stroke,
    );

    // Ascending bars
    void bar(double x, double y, double h) => canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x * s, y * s, 26 * s, h * s),
            Radius.circular(8 * s),
          ),
          fill,
        );
    bar(74, 150, 44);
    bar(115, 118, 76);
    bar(156, 86, 108);

    // Trend line + node
    final path = Path()
      ..moveTo(70 * s, 104 * s)
      ..lineTo(112 * s, 80 * s)
      ..lineTo(150 * s, 96 * s)
      ..lineTo(188 * s, 62 * s);
    canvas.drawPath(path, stroke..strokeWidth = 12 * s);
    canvas.drawCircle(Offset(188 * s, 62 * s), 12 * s, fill);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}
