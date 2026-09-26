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
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/shimmer.dart';
import 'merchant_detail_screen.dart';

/// Every merchant the user has ever transacted with. Tap one to see its full
/// report: total transactions, total sent and received, and every
/// transaction with them.
class MerchantsScreen extends ConsumerStatefulWidget {
  const MerchantsScreen({super.key});

  @override
  ConsumerState<MerchantsScreen> createState() => _MerchantsScreenState();
}

class _MerchantsScreenState extends ConsumerState<MerchantsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final cur = ref.watch(settingsProvider).currency;
    final merchants = ref.watch(allMerchantsProvider);

    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, 130),
        children: [
          Text('Merchants', style: AppType.h1.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _search,
            hint: 'Search merchants',
            icon: Icons.search,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.md),
          const BannerAdCard(),
          const SizedBox(height: AppSpacing.md),
          merchants.when(
            loading: () => Column(
                children: List.generate(
                    5,
                    (_) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Shimmer(height: 64, radius: AppRadii.md)))),
            error: (e, _) => ErrorView(message: '$e'),
            data: (list) {
              final q = _query.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? list
                  : list
                      .where((m) => m.merchant.toLowerCase().contains(q))
                      .toList();
              if (filtered.isEmpty) {
                return EmptyState(
                  emoji: '🏪',
                  title: list.isEmpty ? 'No merchants yet' : 'No matches',
                  message: list.isEmpty
                      ? 'Add or import a few transactions first.'
                      : 'Try a different search.',
                );
              }
              return Column(
                children: [
                  for (final (i, m) in filtered.indexed) ...[
                    _MerchantRow(
                      summary: m,
                      currency: cur,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MerchantDetailScreen(merchant: m.merchant),
                        ),
                      ),
                    ),
                    // Spaced out (not denser): tight ad density is a
                    // common cause of AdMob policy strikes and accidental
                    // clicks, both of which put the whole account at risk.
                    if (i > 0 && i % 6 == 5) ...[
                      const NativeAdCard(),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MerchantRow extends StatelessWidget {
  final MerchantSummary summary;
  final String currency;
  final VoidCallback onTap;
  const _MerchantRow({
    required this.summary,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: c.accentSoft,
              child: Text(
                  summary.merchant.isNotEmpty
                      ? summary.merchant[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: c.accent, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.merchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.h3
                          .copyWith(color: c.textPrimary, fontSize: 15)),
                  Text(
                      '${summary.count} transaction${summary.count == 1 ? '' : 's'} · last ${Dates.relative(summary.lastDate)}',
                      style: AppType.caption.copyWith(color: c.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (summary.sent > 0)
                  Text('-${Money.format(summary.sent, code: currency, compact: true)}',
                      style: TextStyle(
                          color: c.expense,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                if (summary.received > 0)
                  Text('+${Money.format(summary.received, code: currency, compact: true)}',
                      style: TextStyle(
                          color: c.income,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
              ],
            ),
            Icon(Icons.chevron_right, color: c.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
