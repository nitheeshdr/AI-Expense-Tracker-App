import 'package:flutter/material.dart';

import '../design/app_theme.dart';

enum AppButtonKind { primary, secondary, ghost }

/// Material 3 button. [leadingEmoji] is accepted for back-compat but ignored
/// (no emoji); pass [icon] for a Material leading icon instead.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonKind kind;
  final String? leadingEmoji; // ignored (kept for source compatibility)
  final IconData? icon;
  final bool loading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = AppButtonKind.primary,
    this.leadingEmoji,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final disabled = onTap == null || loading;
    final onTapEffective = disabled ? null : onTap;

    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Text(label);

    Widget button;
    switch (kind) {
      case AppButtonKind.primary:
        button = icon != null && !loading
            ? FilledButton.icon(
                onPressed: onTapEffective, icon: Icon(icon), label: child)
            : FilledButton(onPressed: onTapEffective, child: child);
      case AppButtonKind.secondary:
        button = icon != null && !loading
            ? OutlinedButton.icon(
                onPressed: onTapEffective, icon: Icon(icon), label: child)
            : OutlinedButton(onPressed: onTapEffective, child: child);
      case AppButtonKind.ghost:
        button = TextButton(
          onPressed: onTapEffective,
          style: TextButton.styleFrom(
            foregroundColor: c.accent,
            minimumSize: const Size.fromHeight(52),
          ),
          child: child,
        );
    }

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
