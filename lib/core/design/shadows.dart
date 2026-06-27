import 'package:flutter/widgets.dart';

/// Soft, layered shadows for floating elements. Tuned per brightness in [AppTheme].
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card(Color base, {bool dark = true}) => [
        BoxShadow(
          color: base.withValues(alpha: dark ? 0.55 : 0.10),
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 14),
        ),
      ];

  static List<BoxShadow> floating(Color base, {bool dark = true}) => [
        BoxShadow(
          color: base.withValues(alpha: dark ? 0.65 : 0.16),
          blurRadius: 36,
          spreadRadius: -4,
          offset: const Offset(0, 18),
        ),
      ];

  static List<BoxShadow> glow(Color accent) => [
        BoxShadow(
          color: accent.withValues(alpha: 0.45),
          blurRadius: 30,
          spreadRadius: -8,
          offset: const Offset(0, 10),
        ),
      ];
}
