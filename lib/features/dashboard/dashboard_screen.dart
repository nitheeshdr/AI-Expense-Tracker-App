import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/categories.dart';
import '../../core/data/models.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/spacing.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ads/banner_ad_widget.dart';
import '../../core/widgets/animated_count.dart';
import '../../core/widgets/charts/bar_chart.dart';
import '../../core/widgets/charts/donut_chart.dart';
import '../../core/widgets/charts/line_chart.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/shimmer.dart';
import '../add_expense/add_expense_sheet.dart';
import '../transactions/transaction_detail_sheet.dart';
import '../transactions/transaction_row.dart';

/// Home dashboard. Each section is a direct child of a single [ListView] for a
/// robust, properly-aligned vertical layout with real charts.
class DashboardScreen extends ConsumerWidget {
  final VoidCallback onSeeAllTransactions;
  final ValueChanged<int> onOpenTab;
  final VoidCallback onAddExpense;
  final VoidCallback onImportSms;
  const DashboardScreen({
    super.key,
    required this.onSeeAllTransactions,
    required this.onOpenTab,
    required this.onAddExpense,
    required this.onImportSms,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final summaryAsync = ref.watch(monthSummaryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(dataRevisionProvider.notifier).bump();
            await ref.read(monthSummaryProvider.future);
          },
          child: summaryAsync.when(
            loading: () => const _LoadingList(),
            error: (e, _) => ListView(children: [
              const SizedBox(height: 120),
              ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(monthSummaryProvider),
              ),
            ]),
            data: (s) => _DashboardList(
              summary: s,
              settings: settings,
              onSeeAll: onSeeAllTransactions,
              onOpenTab: onOpenTab,
              onAddExpense: onAddExpense,
              onImportSms: onImportSms,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardList extends ConsumerWidget {
  final MonthSummary summary;
  final AppSettings settings;
  final VoidCallback onSeeAll;
  final ValueChanged<int> onOpenTab;
  final VoidCallback onAddExpense;
  final VoidCallback onImportSms;
  const _DashboardList({
    required this.summary,
    required this.settings,
    required this.onSeeAll,
    required this.onOpenTab,
    required this.onAddExpense,
    required this.onImportSms,
  });

  int get _healthScore {
    final rate = summary.income <= 0
        ? 0.0
        : (summary.savings / summary.income).clamp(0, 1);
    final budgetUse = settings.monthlyBudget <= 0
        ? 0.0
        : (summary.expense / settings.monthlyBudget).clamp(0, 2);
    final budgetScore = (1 - (budgetUse - 0.8).clamp(0, 1)).clamp(0, 1);
    return (rate * 55 + budgetScore * 45).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppTheme.of(context);
    final cur = settings.currency;
    final hasData = summary.totalExpense > 0 || summary.income > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 140),
      children: [
        _Greeting(name: settings.userName),
        const SizedBox(height: AppSpacing.lg),

        // Hero net card — tap to see income vs expense breakdown
        GestureDetector(
          onTap: () => _showNetDetail(context, c),
          child: _HeroCard(summary: summary, settings: settings),
        ),
        const SizedBox(height: AppSpacing.sm),
        const BannerAdCard(),
        const SizedBox(height: AppSpacing.sm),

        // Today / Month / Total spend
        Row(
          children: [
            Expanded(
                child: _SpendCard(
                    label: 'Today',
                    value: summary.todayExpense,
                    currency: cur,
                    icon: Icons.today_outlined,
                    hidden: settings.hideBalances)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: _SpendCard(
                    label: 'This month',
                    value: summary.expense,
                    currency: cur,
                    icon: Icons.calendar_month_outlined,
                    hidden: settings.hideBalances)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: _SpendCard(
                    label: 'Total',
                    value: summary.totalExpense,
                    currency: cur,
                    icon: Icons.account_balance_wallet_outlined,
                    hidden: settings.hideBalances)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Explore — feature grid
        const SectionHeader(title: 'Explore'),
        _FeatureGrid(features: [
          _Feature('Add expense', Icons.add_card_outlined, onAddExpense),
          _Feature('Import SMS', Icons.sms_outlined, onImportSms),
          _Feature('AI assistant', Icons.auto_awesome_outlined, () => onOpenTab(2)),
          _Feature('Budgets', Icons.savings_outlined, () => onOpenTab(3)),
          _Feature('Subscriptions', Icons.autorenew, () => onOpenTab(3)),
          _Feature('Transactions', Icons.receipt_long_outlined, () => onOpenTab(1)),
          _Feature('Scan receipt', Icons.document_scanner_outlined,
              () => openComingSoon(context, ref, 'Receipt Scanning', Icons.document_scanner_outlined)),
          _Feature('Profile', Icons.person_outline, () => onOpenTab(4)),
        ]),
        const SizedBox(height: AppSpacing.xl),

        if (!hasData) ...[
          _ImportPrompt(onImportSms: onImportSms),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Health score + AI insight
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Card(
                width: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScoreRing(
                        score: _healthScore,
                        color: _healthScore >= 70
                            ? c.income
                            : _healthScore >= 45
                                ? c.warning
                                : c.expense,
                        size: 84),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Financial health',
                        style: TextStyle(fontSize: 11, color: c.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _AiInsightCard(summary: summary)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Spending trend (line chart)
        const SectionHeader(title: 'Spending trend'),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Last 30 days',
                      style: TextStyle(color: c.textSecondary, fontSize: 13)),
                  if (summary.expenseChangePct != null)
                    Row(children: [
                      Icon(
                          summary.expenseChangePct! >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 16,
                          color: summary.expenseChangePct! >= 0
                              ? c.expense
                              : c.income),
                      const SizedBox(width: 4),
                      Text(
                          '${summary.expenseChangePct!.abs().toStringAsFixed(0)}% vs last mo',
                          style: TextStyle(
                              fontSize: 12,
                              color: summary.expenseChangePct! >= 0
                                  ? c.expense
                                  : c.income)),
                    ]),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              MiniLineChart(
                values: summary.daily.map((d) => d.total).toList(),
                color: c.accent,
                height: 130,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Last 7 days bar chart
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last 7 days',
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
              const SizedBox(height: AppSpacing.md),
              MiniBarChart(
                values: _last7(summary).map((d) => d.total).toList(),
                labels: _last7(summary).map((d) => _wd(d.day)).toList(),
                color: c.accent,
                height: 130,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        const BannerAdCard(),
        const SizedBox(height: AppSpacing.lg),

        // Category breakdown (donut)
        if (summary.byCategory.isNotEmpty) ...[
          const SectionHeader(title: 'Where it went'),
          _Card(
            child: Row(
              children: [
                CategoryDonut(
                  data: summary.byCategory.take(6).toList(),
                  size: 128,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Top',
                          style:
                              TextStyle(fontSize: 11, color: c.textTertiary)),
                      Text(summary.byCategory.first.category,
                          style: TextStyle(
                              fontSize: 13,
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    children: [
                      for (final cat in summary.byCategory.take(5))
                        _LegendRow(
                            total: cat,
                            share: summary.expense <= 0
                                ? 0
                                : cat.total / summary.expense),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Top merchants
        if (summary.topMerchants.isNotEmpty) ...[
          const SectionHeader(title: 'Top merchants'),
          _Card(
            child: Column(
              children: [
                for (final m in summary.topMerchants)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: c.accentSoft,
                          child: Text(
                              m.category.isNotEmpty
                                  ? m.category[0].toUpperCase()
                                  : '?',
                              style: TextStyle(color: c.accent)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(m.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.textPrimary)),
                        ),
                        Text(Money.format(m.total, code: cur),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Recent activity
        SectionHeader(
            title: 'Recent activity', actionLabel: 'See all', onAction: onSeeAll),
        _Card(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: _RecentList(currency: cur, onImportSms: onImportSms),
        ),
      ],
    );
  }

  void _showNetDetail(BuildContext context, AppColors c) {
    final cur = settings.currency;
    showAppSheet<void>(
      context,
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(
                title: 'This month',
                subtitle: 'Income vs expense, and your net position'),
            Row(
              children: [
                Expanded(
                    child: _MiniStat(
                        label: 'Income',
                        value: summary.income,
                        color: c.income,
                        currency: cur)),
                Expanded(
                    child: _MiniStat(
                        label: 'Expense',
                        value: summary.expense,
                        color: c.expense,
                        currency: cur)),
                Expanded(
                    child: _MiniStat(
                        label: 'Saved',
                        value: summary.savings,
                        color: c.accent,
                        currency: cur)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Income · Expense · Saved',
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
            const SizedBox(height: AppSpacing.md),
            MiniBarChart(
              values: [
                summary.income,
                summary.expense,
                summary.savings.clamp(0, double.infinity),
              ],
              labels: const ['In', 'Out', 'Net'],
              color: c.accent,
              height: 150,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Daily spend (last 30 days)',
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
            const SizedBox(height: AppSpacing.md),
            MiniLineChart(
              values: summary.daily.map((d) => d.total).toList(),
              color: c.accent,
              height: 140,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  List<DayTotal> _last7(MonthSummary s) {
    final d = s.daily;
    return d.length <= 7 ? d : d.sublist(d.length - 7);
  }

  String _wd(DateTime d) => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];
}

/// Simple rounded surface card (no shadow).
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: c.hairline),
      ),
      child: child,
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_salutation,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(name == 'there' ? 'Welcome back' : 'Hey, $name',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final MonthSummary summary;
  final AppSettings settings;
  const _HeroCard({required this.summary, required this.settings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cur = settings.currency;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net this month',
              style: TextStyle(
                  color: cs.onPrimary.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: AppSpacing.sm),
          AnimatedMoney(
            value: summary.net,
            currency: cur,
            hidden: settings.hideBalances,
            style: TextStyle(
                color: cs.onPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _HeroStat(
                  label: 'Income',
                  value: summary.income,
                  currency: cur,
                  icon: Icons.south_west,
                  hidden: settings.hideBalances),
              Container(width: 1, height: 34, color: cs.onPrimary.withValues(alpha: 0.2)),
              _HeroStat(
                  label: 'Expense',
                  value: summary.expense,
                  currency: cur,
                  icon: Icons.north_east,
                  hidden: settings.hideBalances),
              Container(width: 1, height: 34, color: cs.onPrimary.withValues(alpha: 0.2)),
              _HeroStat(
                  label: 'Saved',
                  value: summary.savings,
                  currency: cur,
                  icon: Icons.savings_outlined,
                  hidden: settings.hideBalances),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final IconData icon;
  final bool hidden;
  const _HeroStat({
    required this.label,
    required this.value,
    required this.currency,
    required this.icon,
    required this.hidden,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final faint = cs.onPrimary.withValues(alpha: 0.8);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 12, color: faint),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, color: faint)),
            ]),
            const SizedBox(height: 4),
            Text(
              hidden ? '••••' : Money.format(value, code: currency, compact: true),
              style: TextStyle(
                  color: cs.onPrimary, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendCard extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final IconData icon;
  final bool hidden;
  const _SpendCard({
    required this.label,
    required this.value,
    required this.currency,
    required this.icon,
    required this.hidden,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return _Card(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.accent),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hidden ? '••••' : Money.format(value, code: currency, compact: true),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: c.textTertiary)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String currency;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: c.textTertiary)),
        const SizedBox(height: 4),
        Text(Money.format(value, code: currency, compact: true),
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _Feature {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _Feature(this.label, this.icon, this.onTap);
}

class _FeatureGrid extends StatelessWidget {
  final List<_Feature> features;
  const _FeatureGrid({required this.features});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, i) {
        final f = features[i];
        final c = AppTheme.of(context);
        return InkWell(
          onTap: f.onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(f.icon, color: c.accent, size: 24),
              ),
              const SizedBox(height: 6),
              Text(f.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: c.textSecondary)),
            ],
          ),
        );
      },
    );
  }
}

class _ImportPrompt extends StatelessWidget {
  final VoidCallback onImportSms;
  const _ImportPrompt({required this.onImportSms});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return _Card(
      child: Row(
        children: [
          Icon(Icons.sms_outlined, color: c.accent, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Import your transactions',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: c.textPrimary)),
                const SizedBox(height: 2),
                Text('Read bank & UPI SMS to auto-fill your spending.',
                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(onPressed: onImportSms, child: const Text('Import')),
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  final MonthSummary summary;
  const _AiInsightCard({required this.summary});

  String get _insight {
    if (summary.byCategory.isEmpty) {
      return 'Import transactions and I\'ll spot patterns for you.';
    }
    final top = summary.byCategory.first;
    final share =
        summary.expense <= 0 ? 0 : (top.total / summary.expense * 100).round();
    return '$share% of your spend is on ${top.category}.';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: c.accent, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.auto_awesome, size: 16, color: c.onAccent),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Aria insight',
                style: TextStyle(
                    color: c.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ]),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Text(_insight,
                style: TextStyle(
                    color: c.textPrimary, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final CategoryTotal total;
  final double share;
  const _LegendRow({required this.total, required this.share});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final color = Categories.of(total.category).color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(total.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: c.textSecondary)),
          ),
          Text('${(share * 100).round()}%',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
        ],
      ),
    );
  }
}

class _RecentList extends ConsumerWidget {
  final String currency;
  final VoidCallback onImportSms;
  const _RecentList({required this.currency, required this.onImportSms});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentTransactionsProvider);
    return recent.when(
      loading: () =>
          Column(children: List.generate(4, (_) => const SkeletonRow())),
      error: (e, _) => ErrorView(message: '$e'),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              message: 'Import from SMS or add one to get started.',
              ctaLabel: 'Import from SMS',
              onCta: onImportSms,
            ),
          );
        }
        return Column(
          children: [
            for (final t in list)
              TransactionRow(
                txn: t,
                currency: currency,
                onTap: () => showTransactionDetail(context, ref, t),
              ),
          ],
        );
      },
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 140),
      children: const [
        Shimmer(height: 150, radius: AppRadii.xl),
        SizedBox(height: AppSpacing.lg),
        Shimmer(height: 90, radius: AppRadii.lg),
        SizedBox(height: AppSpacing.lg),
        Shimmer(height: 180, radius: AppRadii.lg),
        SizedBox(height: AppSpacing.lg),
        Shimmer(height: 180, radius: AppRadii.lg),
      ],
    );
  }
}
