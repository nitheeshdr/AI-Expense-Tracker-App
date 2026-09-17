import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/models.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ads/banner_ad_widget.dart';
import '../../core/widgets/ads/native_ad_widget.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/shimmer.dart';
import '../transactions/transaction_detail_sheet.dart';
import '../transactions/transaction_row.dart';

/// One merchant's full report: total transactions, total sent (expense) and
/// received (income), net, and every transaction with them.
class MerchantDetailScreen extends ConsumerWidget {
  final String merchant;
  const MerchantDetailScreen({super.key, required this.merchant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cur = ref.watch(settingsProvider).currency;
    final detail = ref.watch(merchantDetailProvider(merchant));

    return Scaffold(
      appBar: AppBar(title: Text(merchant)),
      body: detail.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Shimmer(height: 400, radius: AppRadii.lg),
        ),
        error: (e, _) => ErrorView(message: '$e'),
        data: (d) {
          if (d == null) {
            return const EmptyState(
              emoji: '🏪',
              title: 'No transactions',
              message: 'This merchant has no recorded transactions.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, 40),
            children: [
              _SummaryCard(summary: d.summary, currency: cur),
              const SizedBox(height: AppSpacing.sm),
              const BannerAdCard(),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'All transactions'),
              for (final (i, txn) in d.transactions.indexed) ...[
                TransactionRow(
                  txn: txn,
                  currency: cur,
                  onTap: () => showTransactionDetail(context, ref, txn),
                ),
                if (i == 4) ...[
                  const NativeAdCard(),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final MerchantSummary summary;
  final String currency;
  const _SummaryCard({required this.summary, required this.currency});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return GlassCard(
      radius: AppRadii.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${summary.count}',
                  style: AppType.numericLarge.copyWith(color: c.textPrimary)),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('transactions',
                    style: AppType.body.copyWith(color: c.textSecondary)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Last ${Dates.relative(summary.lastDate)}',
                style: AppType.caption.copyWith(color: c.textTertiary)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _Stat(
                    label: 'Sent',
                    value: summary.sent,
                    currency: currency,
                    color: c.expense),
              ),
              Expanded(
                child: _Stat(
                    label: 'Received',
                    value: summary.received,
                    currency: currency,
                    color: c.income),
              ),
              Expanded(
                child: _Stat(
                    label: 'Net',
                    value: summary.net,
                    currency: currency,
                    color: c.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final Color color;
  const _Stat({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.caption.copyWith(color: c.textTertiary)),
        const SizedBox(height: 2),
        Text(Money.format(value, code: currency, compact: true),
            style: AppType.h3.copyWith(color: color, fontSize: 15)),
      ],
    );
  }
}
