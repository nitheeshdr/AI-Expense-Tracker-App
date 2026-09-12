import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/spacing.dart';
import '../../core/widgets/app_sheet.dart';
import 'review_prompt_service.dart';
import 'review_service.dart';

/// Checks whether an engaged user should be asked to review the app, and if
/// so shows the prompt. Safe to call from anywhere (e.g. once per app open);
/// it silently no-ops when criteria aren't met. Call after the first frame
/// so `context` is ready for the sheet.
Future<void> maybeShowReviewPrompt(BuildContext context, WidgetRef ref) async {
  final count = await ref.read(transactionRepoProvider).count();
  if (!await ReviewPromptService.instance.shouldPrompt(count)) return;
  await ReviewPromptService.instance.markPrompted();
  if (!context.mounted) return;
  await showAppSheet<void>(
    context,
    dismissible: false,
    builder: (_) => const _ReviewPromptSheet(),
  );
}

class _ReviewPromptSheet extends StatelessWidget {
  const _ReviewPromptSheet();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.star_rounded, color: c.accent, size: 40),
        const SizedBox(height: AppSpacing.md),
        const SheetHeader(
          title: 'Enjoying AI Expense Tracker?',
          subtitle:
              'A quick rating helps a lot more than you\'d think — got a second?',
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            ReviewService.instance.requestReview();
          },
          icon: const Icon(Icons.star_outline),
          label: const Text('Rate now'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Maybe later'),
        ),
        TextButton(
          onPressed: () {
            ReviewPromptService.instance.markNeverAskAgain();
            Navigator.of(context).pop();
          },
          child: Text('No thanks', style: TextStyle(color: c.textTertiary)),
        ),
      ],
    );
  }
}
