import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import '../design/spacing.dart';

/// Material 3 surface card. Retains the original constructor surface so screens
/// compile unchanged. Renders as a tonal container with rounded corners and an
/// optional gradient (used for hero cards).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool glass;
  final bool elevated;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final BoxBorder? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.lg,
    this.glass = false,
    this.elevated = false,
    this.gradient,
    this.color,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final br = BorderRadius.circular(radius);

    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? c.surface) : null,
      gradient: gradient,
      borderRadius: br,
      border: border ?? Border.all(color: c.hairline),
    );

    final content = DecoratedBox(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return Material(
        color: Colors.transparent,
        child: ClipRRect(borderRadius: br, child: content),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        child: ClipRRect(borderRadius: br, child: content),
      ),
    );
  }
}
