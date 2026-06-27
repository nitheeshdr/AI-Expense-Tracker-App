import 'package:flutter/widgets.dart';

import '../../design/app_theme.dart';
import '../../design/typography.dart';
import 'line_chart.dart' show compactNum;

/// Simple animated vertical bars (e.g. weekday spending). Bars grow from the
/// baseline with a staggered feel via a single eased progress value.
class MiniBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  final Color? color;

  const MiniBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 130,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final col = color ?? c.accent;
    final maxV = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        values[i] > 0 ? compactNum(values[i] * t) : '',
                        style: AppType.caption
                            .copyWith(color: c.textSecondary, fontSize: 9),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: (values[i] / maxV) * (height - 42) * t + 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: col,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        i < labels.length ? labels[i] : '',
                        style: AppType.caption.copyWith(color: c.textTertiary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
