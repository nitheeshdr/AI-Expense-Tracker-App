import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/categories.dart';
import '../../core/data/models.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ads/banner_ad_widget.dart';
import '../../core/widgets/ads/native_ad_widget.dart';
import '../../core/widgets/animated_count.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/shimmer.dart';
import 'budget_sheets.dart';

/// Budgets (overall + per-category, with live spent progress) and savings goals.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppTheme.of(context);
    final cur = ref.watch(settingsProvider).currency;
    final budgets = ref.watch(budgetsProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final summary = ref.watch(monthSummaryProvider);
    final subscriptions = ref.watch(subscriptionsProvider);

    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, 130),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budgets',
                  style: AppType.h1.copyWith(color: c.textPrimary)),
              IconButton.filledTonal(
                onPressed: () => showBudgetEditor(context, ref),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Overall budget hero ring
          budgets.when(
            loading: () => const Shimmer(height: 170, radius: AppRadii.lg),
            error: (e, _) => ErrorView(message: '$e'),
            data: (list) {
              final overall = list
                  .where((b) => b.category == 'Overall')
                  .fold(0.0, (a, b) => a + b.amount);
              final spent = summary.value?.expense ?? 0;
              return _OverallCard(
                  budget: overall, spent: spent, currency: cur);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          const BannerAdCard(),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Category budgets'),
          budgets.when(
            loading: () => Column(
                children: List.generate(
                    3, (_) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: Shimmer(height: 64, radius: AppRadii.md)))),
            error: (e, _) => ErrorView(message: '$e'),
            data: (list) {
              final cats = list.where((b) => b.category != 'Overall').toList();
              if (cats.isEmpty) {
                return const EmptyState(
                  emoji: '🎯',
                  title: 'No category budgets',
                  message: 'Add one with the + button above.',
                );
              }
              return Column(
                children: [
                  for (final b in cats)
                    _CategoryBudgetCard(
                      budget: b,
                      currency: cur,
                      onEdit: () =>
                          showBudgetEditor(context, ref, existing: b),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const NativeAdCard(),
          const SizedBox(height: AppSpacing.lg),

          // Subscriptions & autopay
          const SectionHeader(title: 'Subscriptions & autopay'),
          subscriptions.when(
            loading: () => const Shimmer(height: 70, radius: AppRadii.lg),
            error: (e, _) => ErrorView(message: '$e'),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.autorenew,
                  title: 'No recurring bills yet',
                  message:
                      'Subscriptions and autopay from your SMS will appear here.',
                );
              }
              final monthly = list.fold(0.0, (a, s) => a + s.amount);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Text('${list.length} active',
                            style: AppType.bodySm
                                .copyWith(color: c.textSecondary)),
                        const Spacer(),
                        Text(
                            '~${Money.format(monthly, code: cur, compact: true)} / mo',
                            style: AppType.bodySm.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  for (final sub in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            CategoryIcon(category: sub.category, size: 42),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sub.merchant,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppType.h3.copyWith(
                                          color: c.textPrimary, fontSize: 15)),
                                  Text(
                                      '${sub.category} · last ${Dates.relative(sub.lastDate)}',
                                      style: AppType.caption
                                          .copyWith(color: c.textTertiary)),
                                ],
                              ),
                            ),
                            Text(Money.format(sub.amount, code: cur),
                                style: AppType.numericMedium.copyWith(
                                    fontSize: 15, color: c.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Savings goals',
                  style: AppType.h2.copyWith(color: c.textPrimary)),
              GestureDetector(
                onTap: () => showGoalEditor(context, ref),
                child: Text('Add goal',
                    style: AppType.bodySm.copyWith(color: c.accent)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          goals.when(
            loading: () => const Shimmer(height: 90, radius: AppRadii.lg),
            error: (e, _) => ErrorView(message: '$e'),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  emoji: '🏖️',
                  title: 'No goals yet',
                  message: 'Set a target to start saving toward it.',
                );
              }
              return Column(
                children: [
                  for (final g in list)
                    _GoalCard(
                      goal: g,
                      currency: cur,
                      onTap: () => showGoalEditor(context, ref, existing: g),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final double budget;
  final double spent;
  final String currency;
  const _OverallCard({
    required this.budget,
    required this.spent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final pct = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final over = spent > budget && budget > 0;
    final ringColor = pct < 0.7
        ? c.income
        : pct < 1
            ? c.warning
            : c.expense;
    return GlassCard(
      radius: AppRadii.xl,
      child: Row(
        children: [
          ProgressRing(
            progress: pct,
            size: 104,
            stroke: 11,
            color: ringColor,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(pct * 100).round()}%',
                    style: AppType.h2.copyWith(color: c.textPrimary)),
                Text('used',
                    style: AppType.caption.copyWith(color: c.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly budget',
                    style: AppType.label.copyWith(color: c.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                AnimatedMoney(
                  value: spent,
                  currency: currency,
                  style: AppType.numericMedium.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: 2),
                Text('of ${Money.format(budget, code: currency)}',
                    style: AppType.bodySm.copyWith(color: c.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                StatusPill(
                  label: over
                      ? 'Over by ${Money.format(spent - budget, code: currency, compact: true)}'
                      : '${Money.format(budget - spent, code: currency, compact: true)} left',
                  emoji: over ? '⚠️' : '✅',
                  color: over ? c.expense : c.income,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBudgetCard extends ConsumerWidget {
  final BudgetEntity budget;
  final String currency;
  final VoidCallback onEdit;
  const _CategoryBudgetCard({
    required this.budget,
    required this.currency,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppTheme.of(context);
    final spentAsync = ref.watch(_categorySpentProvider(budget.category));
    final spent = spentAsync.value ?? 0;
    final pct = budget.amount <= 0
        ? 0.0
        : (spent / budget.amount).clamp(0.0, 1.0);
    final color = Categories.of(budget.category).color;
    final over = spent > budget.amount;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        onTap: onEdit,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                CategoryIcon(category: budget.category, size: 42),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budget.category,
                          style: AppType.h3
                              .copyWith(color: c.textPrimary, fontSize: 15)),
                      Text(
                          '${Money.format(spent, code: currency)} of ${Money.format(budget.amount, code: currency)}',
                          style: AppType.caption
                              .copyWith(color: c.textTertiary)),
                    ],
                  ),
                ),
                Text('${(pct * 100).round()}%',
                    style: AppType.numericMedium.copyWith(
                        fontSize: 15,
                        color: over ? c.expense : c.textPrimary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Bar(progress: pct, color: over ? c.expense : color),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double progress;
  final Color color;
  const _Bar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Stack(
        children: [
          Container(height: 8, color: c.hairline),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v.clamp(0.0, 1.0),
              child: Container(height: 8, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoalEntity goal;
  final String currency;
  final VoidCallback onTap;
  const _GoalCard({
    required this.goal,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            ProgressRing(
              progress: goal.progress,
              size: 58,
              stroke: 7,
              color: c.accent,
              center: Text('${(goal.progress * 100).round()}%',
                  style: AppType.caption.copyWith(color: c.textPrimary)),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.name,
                      style: AppType.h3
                          .copyWith(color: c.textPrimary, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                      '${Money.format(goal.saved, code: currency)} of ${Money.format(goal.target, code: currency)}',
                      style: AppType.bodySm.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-category spent for the current month (kept tiny + auto-invalidated).
final _categorySpentProvider =
    FutureProvider.family<double, String>((ref, category) async {
  ref.watch(dataRevisionProvider);
  final range = currentMonthRange();
  return ref
      .watch(transactionRepoProvider)
      .spentInCategory(category, range.start, range.end);
});
