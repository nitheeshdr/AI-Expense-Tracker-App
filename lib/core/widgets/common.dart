import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import '../design/spacing.dart';
import 'app_button.dart';

/// Section header with a title and optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Centered empty state. [emoji] is accepted but ignored; [icon] renders.
class EmptyState extends StatelessWidget {
  final String emoji; // ignored
  final IconData icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    this.emoji = '',
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            if (ctaLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(label: ctaLabel!, expand: false, onTap: onCta),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with retry.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 40, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text('Something went wrong', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                  label: 'Retry',
                  kind: AppButtonKind.secondary,
                  expand: false,
                  onTap: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thin status pill (e.g. "SMS", payment tags). [emoji] ignored; [icon] renders.
class StatusPill extends StatelessWidget {
  final String label;
  final Color? color;
  final String? emoji; // ignored
  final IconData? icon;
  const StatusPill({
    super.key,
    required this.label,
    this.color,
    this.emoji,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final col = color ?? c.textSecondary;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: col.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: col),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  color: col, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
