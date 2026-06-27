import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/models.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/category_icon.dart';
import '../add_expense/add_expense_sheet.dart';

/// Read view of a transaction with edit + delete actions.
Future<void> showTransactionDetail(
  BuildContext context,
  WidgetRef ref,
  TransactionEntity txn,
) {
  return showAppSheet<void>(
    context,
    builder: (context) => _DetailSheet(txn: txn),
  );
}

class _DetailSheet extends ConsumerWidget {
  final TransactionEntity txn;
  const _DetailSheet({required this.txn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppTheme.of(context);
    final cur = ref.watch(settingsProvider).currency;
    final isIncome = txn.type == TxnType.income;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              CategoryIcon(category: txn.category, size: 64),
              const SizedBox(height: AppSpacing.md),
              Text(txn.merchant,
                  style: AppType.h2.copyWith(color: c.textPrimary)),
              const SizedBox(height: 4),
              Text(
                Money.signed(isIncome ? txn.amount : -txn.amount, code: cur),
                style: AppType.numericLarge.copyWith(
                  fontSize: 32,
                  color: isIncome ? c.income : c.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _row(c, 'Category', txn.category),
        _row(c, 'Date', Dates.full(txn.date)),
        _row(c, 'Payment', txn.paymentMethod ?? '—'),
        if (txn.bank != null) _row(c, 'Bank', txn.bank!),
        _row(c, 'Source', _sourceLabel(txn.source)),
        if (txn.referenceNo != null) _row(c, 'Reference', txn.referenceNo!),
        if (txn.note != null) _row(c, 'Note', txn.note!),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Edit',
                kind: AppButtonKind.secondary,
                leadingEmoji: '✏️',
                onTap: () {
                  Navigator.of(context).pop();
                  openAddExpense(context, ref, edit: txn);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Delete',
                kind: AppButtonKind.ghost,
                leadingEmoji: '🗑️',
                onTap: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Delete transaction?',
                    message: 'This can\'t be undone.',
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                  if (!ok) return;
                  await ref.read(transactionRepoProvider).delete(txn.id);
                  ref.read(dataRevisionProvider.notifier).bump();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _sourceLabel(TxnSource s) => switch (s) {
        TxnSource.manual => 'Manual entry',
        TxnSource.sms => 'Bank SMS',
        TxnSource.receipt => 'Receipt scan',
        TxnSource.imported => 'Imported',
        TxnSource.voice => 'Voice',
      };

  Widget _row(AppColors c, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: AppType.bodySm.copyWith(color: c.textTertiary)),
          ),
          Expanded(
            child: Text(value,
                style: AppType.body.copyWith(
                    color: c.textPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
