import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import 'sms_import_controller.dart';

/// Bottom sheet that requests SMS permission and imports bank/UPI transactions.
Future<void> showSmsImportSheet(BuildContext context, WidgetRef ref) {
  return showAppSheet<void>(
    context,
    builder: (context) => const _SmsImportSheet(),
  );
}

class _SmsImportSheet extends ConsumerWidget {
  const _SmsImportSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smsImportProvider);
    final theme = Theme.of(context);
    final busy = state.phase == SmsImportPhase.requesting ||
        state.phase == SmsImportPhase.importing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetHeader(
          title: 'Import from SMS',
          subtitle:
              'We read your bank & UPI messages on-device, detect transactions, and never upload your SMS anywhere.',
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            children: [
              Icon(_phaseIcon(state.phase), color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  state.message ??
                      'Grant SMS access to auto-detect your recent transactions.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: busy
              ? 'Reading SMS…'
              : state.phase == SmsImportPhase.done
                  ? 'Import again'
                  : 'Grant access & import',
          icon: Icons.sms_outlined,
          loading: busy,
          onTap: busy
              ? null
              : () => ref.read(smsImportProvider.notifier).importInbox(),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.phase == SmsImportPhase.done)
          AppButton(
            label: 'Done',
            kind: AppButtonKind.secondary,
            onTap: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  IconData _phaseIcon(SmsImportPhase phase) => switch (phase) {
        SmsImportPhase.done => Icons.check_circle_outline,
        SmsImportPhase.denied => Icons.error_outline,
        SmsImportPhase.unsupported => Icons.info_outline,
        SmsImportPhase.importing => Icons.downloading_outlined,
        SmsImportPhase.requesting => Icons.lock_open_outlined,
        SmsImportPhase.idle => Icons.sms_outlined,
      };
}
