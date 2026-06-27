import 'package:flutter/widgets.dart';

import '../utils/formatters.dart';

/// Tweens a monetary value from 0 → target with tabular figures, for the
/// "counting up" hero balance effect. Respects the optional hide-balances mask.
class AnimatedMoney extends StatelessWidget {
  final double value;
  final String currency;
  final TextStyle style;
  final bool compact;
  final bool hidden;
  final Duration duration;

  const AnimatedMoney({
    super.key,
    required this.value,
    required this.currency,
    required this.style,
    this.compact = false,
    this.hidden = false,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    if (hidden) {
      return Text('••••••', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        Money.format(v, code: currency, compact: compact),
        style: style,
      ),
    );
  }
}
