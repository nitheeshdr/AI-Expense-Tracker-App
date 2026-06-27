import 'package:flutter/widgets.dart';

import '../../core/data/models.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/pressable.dart';

/// Canonical transaction list row, reused on the dashboard and the
/// transactions timeline.
class TransactionRow extends StatelessWidget {
  final TransactionEntity txn;
  final String currency;
  final VoidCallback? onTap;

  const TransactionRow({
    super.key,
    required this.txn,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final isIncome = txn.type == TxnType.income;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            CategoryIcon(category: txn.category, size: 46),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.merchant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.h3
                        .copyWith(color: c.textPrimary, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(txn.category,
                          style: AppType.caption
                              .copyWith(color: c.textTertiary)),
                      Text('  ·  ',
                          style: AppType.caption
                              .copyWith(color: c.textTertiary)),
                      Text(Dates.time(txn.date),
                          style: AppType.caption
                              .copyWith(color: c.textTertiary)),
                      if (txn.source == TxnSource.sms) ...[
                        Text('  ·  ',
                            style: AppType.caption
                                .copyWith(color: c.textTertiary)),
                        Text('SMS',
                            style: AppType.caption
                                .copyWith(color: c.info, fontSize: 9.5)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              Money.signed(isIncome ? txn.amount : -txn.amount,
                  code: currency),
              style: AppType.numericMedium.copyWith(
                fontSize: 15,
                color: isIncome ? c.income : c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
