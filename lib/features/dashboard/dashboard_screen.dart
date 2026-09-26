import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../app/providers.dart';
import '../ai_assistant/ai_controller.dart';
import '../../core/data/categories.dart';
import '../../core/data/models.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/spacing.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ads/banner_ad_widget.dart';
import '../../core/widgets/ads/native_ad_widget.dart';
import '../../core/widgets/ads/rewarded_ad_flow.dart';
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
            error: (e, _) => ListView(
              children: [
                const SizedBox(height: 120),
                ErrorView(
                  message: '$e',
                  onRetry: () => ref.invalidate(monthSummaryProvider),
                ),
              ],
            ),
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

    // Overscroll disabled: the Explore grid below has real LiquidGlassButton
    // icons as list items. The package's README documents that a lens
    // inside a scrollable reads solid black specifically during Android's
    // stretch-overscroll (the pull wraps the list in its own texture that
    // doesn't include the page behind it) — not from ordinary scrolling.
    // This doesn't affect RefreshIndicator above: pull-to-refresh is driven
    // by scroll notifications, not by the decorative stretch effect.
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          140,
        ),
        children: [
          _Greeting(name: settings.userName),
          const SizedBox(height: AppSpacing.lg),

          // Hero net card — tap to see income vs expense breakdown
          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.xl),
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
                  hidden: settings.hideBalances,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SpendCard(
                  label: 'This month',
                  value: summary.expense,
                  currency: cur,
                  icon: Icons.calendar_month_outlined,
                  hidden: settings.hideBalances,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SpendCard(
                  label: 'Total',
                  value: summary.totalExpense,
                  currency: cur,
                  icon: Icons.account_balance_wallet_outlined,
                  hidden: settings.hideBalances,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Smart insights
          const SectionHeader(title: 'Insights'),
          _InsightsRow(summary: summary, settings: settings),
          const SizedBox(height: AppSpacing.xl),

          // Explore — feature grid
          const SectionHeader(title: 'Explore'),
          _FeatureGrid(
            features: [
              _Feature('Add expense', Icons.add_card_outlined, onAddExpense),
              _Feature('Import SMS', Icons.sms_outlined, onImportSms),
              _Feature(
                'AI assistant',
                Icons.auto_awesome_outlined,
                () => onOpenTab(2),
              ),
              _Feature('Budgets', Icons.savings_outlined, () => onOpenTab(3)),
              _Feature('Subscriptions', Icons.autorenew, () => onOpenTab(3)),
              _Feature(
                'Transactions',
                Icons.receipt_long_outlined,
                () => onOpenTab(1),
              ),
              _Feature(
                'Scan receipt',
                Icons.document_scanner_outlined,
                () => openScanReceipt(context, ref),
              ),
              _Feature('Profile', Icons.person_outline, () => onOpenTab(5)),
            ],
          ),
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
                        size: 84,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Financial health',
                        style: TextStyle(fontSize: 11, color: c.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _AiInsightCard(summary: summary, onOpenTab: onOpenTab),
                ),
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
                    Text(
                      'Last 30 days',
                      style: TextStyle(color: c.textSecondary, fontSize: 13),
                    ),
                    if (summary.expenseChangePct != null)
                      Row(
                        children: [
                          Icon(
                            summary.expenseChangePct! >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 16,
                            color: summary.expenseChangePct! >= 0
                                ? c.expense
                                : c.income,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${summary.expenseChangePct!.abs().toStringAsFixed(0)}% vs last mo',
                            style: TextStyle(
                              fontSize: 12,
                              color: summary.expenseChangePct! >= 0
                                  ? c.expense
                                  : c.income,
                            ),
                          ),
                        ],
                      ),
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
                Text(
                  'Last 7 days',
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
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

          // Month heatmap
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Dates.monthYear(DateTime.now())} heatmap',
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.md),
                _MonthHeatmap(daily: summary.daily),
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
                        Text(
                          'Top',
                          style: TextStyle(fontSize: 11, color: c.textTertiary),
                        ),
                        Text(
                          summary.byCategory.first.category,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                                : cat.total / summary.expense,
                          ),
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
                              style: TextStyle(color: c.accent),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              m.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.textPrimary),
                            ),
                          ),
                          Text(
                            Money.format(m.total, code: cur),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          const NativeAdCard(),
          const SizedBox(height: AppSpacing.lg),

          // Recent activity
          SectionHeader(
            title: 'Recent activity',
            actionLabel: 'See all',
            onAction: onSeeAll,
          ),
          _Card(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: _RecentList(currency: cur, onImportSms: onImportSms),
          ),
        ],
      ),
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
              subtitle: 'Income vs expense, and your net position',
            ),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Income',
                    value: summary.income,
                    color: c.income,
                    currency: cur,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Expense',
                    value: summary.expense,
                    color: c.expense,
                    currency: cur,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Saved',
                    value: summary.savings,
                    color: c.accent,
                    currency: cur,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Income · Expense · Saved',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
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
            Text(
              'Daily spend (last 30 days)',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
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

  String _wd(DateTime d) =>
      const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];
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
    return SizedBox(
      width: width,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Padding(padding: padding, child: child),
      ),
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
        Text(
          '$_salutation · ${Dates.dayMonth(DateTime.now())}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name == 'there' ? 'Welcome back' : 'Hey, $name',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
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
    return Card(
      color: cs.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net this month',
              style: TextStyle(
                color: cs.onPrimary.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedMoney(
              value: summary.net,
              currency: cur,
              hidden: settings.hideBalances,
              style: TextStyle(
                color: cs.onPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                _HeroStat(
                  label: 'Income',
                  value: summary.income,
                  currency: cur,
                  icon: Icons.south_west,
                  hidden: settings.hideBalances,
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: cs.onPrimary.withValues(alpha: 0.2),
                ),
                _HeroStat(
                  label: 'Expense',
                  value: summary.expense,
                  currency: cur,
                  icon: Icons.north_east,
                  hidden: settings.hideBalances,
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: cs.onPrimary.withValues(alpha: 0.2),
                ),
                _HeroStat(
                  label: 'Saved',
                  value: summary.savings,
                  currency: cur,
                  icon: Icons.savings_outlined,
                  hidden: settings.hideBalances,
                ),
              ],
            ),
          ],
        ),
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
            Row(
              children: [
                Icon(icon, size: 12, color: faint),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 11, color: faint)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hidden
                  ? '••••'
                  : Money.format(value, code: currency, compact: true),
              style: TextStyle(
                color: cs.onPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
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
            hidden
                ? '••••'
                : Money.format(value, code: currency, compact: true),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: c.textTertiary)),
        ],
      ),
    );
  }
}

/// Horizontally scrollable smart-insight cards computed from real data:
/// daily average, month-end forecast vs budget, biggest spend day, no-spend days.
class _InsightsRow extends StatelessWidget {
  final MonthSummary summary;
  final AppSettings settings;
  const _InsightsRow({required this.summary, required this.settings});

  @override
  Widget build(BuildContext context) {
    final cur = settings.currency;
    final now = DateTime.now();
    final daysElapsed = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final avgPerDay = daysElapsed > 0 ? summary.expense / daysElapsed : 0.0;
    final projected = avgPerDay * daysInMonth;
    final budget = settings.monthlyBudget;
    final overPace = budget > 0 && projected > budget;

    final monthDays = summary.daily
        .where((d) => d.day.month == now.month)
        .toList();
    DayTotal? biggest;
    var noSpend = 0;
    for (final d in monthDays) {
      if (d.day.day > daysElapsed) continue;
      if (d.total <= 0) noSpend++;
      if (biggest == null || d.total > biggest.total) biggest = d;
    }

    final cards = <Widget>[
      _InsightCard(
        icon: Icons.speed_outlined,
        value: Money.format(avgPerDay, code: cur, compact: true),
        label: 'Avg / day',
      ),
      _InsightCard(
        icon: overPace ? Icons.trending_up : Icons.verified_outlined,
        value: Money.format(projected, code: cur, compact: true),
        label: overPace ? 'Forecast · over budget' : 'Forecast · on track',
        emphasized: overPace,
      ),
      if (biggest != null && biggest.total > 0)
        _InsightCard(
          icon: Icons.local_fire_department_outlined,
          value: Money.format(biggest.total, code: cur, compact: true),
          label: 'Peak · ${Dates.dayMonth(biggest.day)}',
        ),
      _InsightCard(
        icon: Icons.self_improvement_outlined,
        value: '$noSpend',
        label: 'No-spend days',
      ),
    ];

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool emphasized;
  const _InsightCard({
    required this.icon,
    required this.value,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    // Emphasized card gets a warning-tinted container (this is only used for
    // the "over budget" forecast) instead of a plain neutral surface.
    final bg = emphasized ? c.warningContainer : c.surface;
    final fg = emphasized ? c.onWarningContainer : c.textPrimary;
    final sub = emphasized
        ? c.onWarningContainer.withValues(alpha: 0.75)
        : c.textTertiary;
    return SizedBox(
      width: 148,
      child: Card(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: fg),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Calendar-style month heatmap: one cell per day, shaded by spend intensity
/// on the monochrome ladder. Future days render as faint outlines.
class _MonthHeatmap extends StatelessWidget {
  final List<DayTotal> daily;
  const _MonthHeatmap({required this.daily});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday; // 1=Mon

    final byDay = <int, double>{
      for (final d in daily)
        if (d.day.month == now.month && d.day.year == now.year)
          d.day.day: d.total,
    };
    final maxSpend = byDay.values.isEmpty
        ? 0.0
        : byDay.values.reduce((a, b) => a > b ? a : b);

    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final cells = <Widget>[
      for (final l in labels)
        Center(
          child: Text(l, style: TextStyle(fontSize: 10, color: c.textTertiary)),
        ),
      for (var i = 1; i < firstWeekday; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _heatCell(context, day, byDay[day] ?? 0, maxSpend, day > now.day),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      children: cells,
    );
  }

  Widget _heatCell(
    BuildContext context,
    int day,
    double spend,
    double maxSpend,
    bool future,
  ) {
    final c = AppTheme.of(context);
    final intensity = maxSpend <= 0 ? 0.0 : (spend / maxSpend).clamp(0.0, 1.0);
    final fill = future
        ? Colors.transparent
        : c.textPrimary.withValues(alpha: 0.05 + intensity * 0.9);
    final showInk = !future && intensity > 0.45;
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: future ? c.hairline : Colors.transparent),
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: showInk
              ? c.background
              : c.textTertiary.withValues(alpha: future ? 0.5 : 1),
        ),
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
        Text(
          Money.format(value, code: currency, compact: true),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
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
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LiquidGlassButton(
              onPressed: f.onTap,
              height: 50,
              width: 50,
              padding: EdgeInsets.zero,
              icon: f.icon,
              iconSize: 24,
              foregroundColor: c.accent,
              style: LiquidGlassButton.defaultStyle.copyWith(
                // An actual circle (plain circular corners), not the
                // squircle-ish look `continuousRoundedRectangle` gives at
                // this size.
                shape: const LiquidGlassShape.roundedRectangle(
                  cornerRadius: 25,
                  borderWidth: 0,
                ),
                appearance: LiquidGlassButton.defaultStyle.appearance.copyWith(
                  color: c.accentSoft,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              f.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: c.textSecondary),
            ),
          ],
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
                Text(
                  'Import your transactions',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Read bank & UPI SMS to auto-fill your spending.',
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: onImportSms,
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

class _AiInsightCard extends ConsumerWidget {
  final MonthSummary summary;
  final ValueChanged<int> onOpenTab;
  const _AiInsightCard({required this.summary, required this.onOpenTab});

  String get _insight {
    if (summary.byCategory.isEmpty) {
      return 'Import transactions and I\'ll spot patterns for you.';
    }
    final top = summary.byCategory.first;
    final share = summary.expense <= 0
        ? 0
        : (top.total / summary.expense * 100).round();
    return '$share% of your spend is on ${top.category}.';
  }

  Future<void> _watchAdForDeeperReport(
      BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final earned = await tryShowRewardedAd(context, ref);
    if (!earned) {
      if (context.mounted) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Watch the full ad to unlock the deeper report.')));
      }
      return;
    }
    onOpenTab(2);
    unawaited(ref.read(aiControllerProvider.notifier).send(
        'Give me a detailed breakdown of my spending this month — top '
        'categories, any unusual patterns, and one concrete suggestion to '
        'save more.'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppTheme.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome, size: 16, color: c.onAccent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Aria insight',
                style: TextStyle(
                  color: c.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Text(
              _insight,
              style: TextStyle(color: c.textPrimary, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => _watchAdForDeeperReport(context, ref),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_outline, size: 14, color: c.accent),
                const SizedBox(width: 4),
                Text(
                  'Get a deeper report',
                  style: TextStyle(
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              total.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ),
          Text(
            '${(share * 100).round()}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
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
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        140,
      ),
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
