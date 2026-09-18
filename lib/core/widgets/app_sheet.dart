import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../design/app_theme.dart';
import '../design/spacing.dart';

/// Presents a liquid-glass modal bottom sheet (rounded, draggable,
/// scrollable). `showLiquidGlassSheet` is Flutter's own
/// `showModalBottomSheet` underneath — same route, drag and dismissal —
/// with a `LiquidGlassSheet` standing in for the sheet's usual filled
/// Material surface.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showLiquidGlassSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    useSafeArea: true,
    padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
    style: LiquidGlassStyle(
      appearance: LiquidGlassAppearance(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.82),
        blur: const LiquidGlassBlur(sigmaX: 16, sigmaY: 16),
        shadow: const LiquidGlassShadow(blur: 12, opacity: 0.16),
      ),
      refraction: const LiquidGlassRefraction(distortion: 0.05, distortionWidth: 22),
    ),
    builder: builder,
  );
}

/// Header row for sheet contents.
class SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SheetHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Liquid-glass confirm dialog. Returns true if confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final c = AppColors.of(context);
  final scheme = Theme.of(context).colorScheme;
  final result = await showLiquidGlassDialog<bool>(
    context: context,
    builder: (context) => LiquidGlassAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        LiquidGlassButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          height: 40,
          style: LiquidGlassButton.defaultStyle.copyWith(
            appearance: LiquidGlassButton.defaultStyle.appearance.copyWith(
              color: destructive ? c.expense : scheme.primary,
            ),
          ),
          foregroundColor: Colors.white,
        ),
      ],
    ),
  );
  return result ?? false;
}
