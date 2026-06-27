import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/models.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/date_grouping.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/ads/banner_ad_widget.dart';
import '../../core/widgets/ads/native_ad_widget.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/shimmer.dart';
import 'transaction_detail_sheet.dart';
import 'transaction_row.dart';

/// Searchable, filterable timeline grouped into Today / Yesterday / This Week /
/// This Month / Older, with swipe-to-delete on each row.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _search = TextEditingController();
  String _query = '';
  _Filter _filter = _Filter.all;
  String? _category;
  _Sort _sort = _Sort.dateDesc;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<TransactionEntity> _apply(List<TransactionEntity> all) {
    final list = all.where((t) {
      if (_filter == _Filter.income && t.type != TxnType.income) return false;
      if (_filter == _Filter.expense && t.type != TxnType.expense) return false;
      if (_category != null && t.category != _category) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return t.merchant.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          (t.note?.toLowerCase().contains(q) ?? false);
    }).toList();
    switch (_sort) {
      case _Sort.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
      case _Sort.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
      case _Sort.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
      case _Sort.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return list;
  }


  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final cur = ref.watch(settingsProvider).currency;
    final txns = ref.watch(allTransactionsProvider);

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH,
                AppSpacing.md, AppSpacing.screenH, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity',
                    style: AppType.h1.copyWith(color: c.textPrimary)),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _search,
                  hint: 'Search merchant, category, note…',
                  icon: Icons.search,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    for (final f in _Filter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _FilterChip(
                          label: f.label,
                          active: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                      ),
                    const Spacer(),
                    _SortButton(
                      current: _sort,
                      onSelected: (s) => setState(() => _sort = s),
                    ),
                  ],
                ),
                // Category filter strip (built from data below).
                _CategoryStrip(
                  selected: _category,
                  onSelected: (cat) => setState(() => _category = cat),
                ),
                const BannerAdCard(),
              ],
            ),
          ),
          Expanded(
            child: txns.when(
              loading: () => ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenH),
                children: List.generate(7, (_) => const SkeletonRow()),
              ),
              error: (e, _) => ErrorView(
                  message: '$e',
                  onRetry: () => ref.invalidate(allTransactionsProvider)),
              data: (all) {
                final filtered = _apply(all);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: _query.isEmpty
                        ? Icons.receipt_long_outlined
                        : Icons.search_off_outlined,
                    title: _query.isEmpty
                        ? 'No transactions yet'
                        : 'No matches',
                    message: _query.isEmpty
                        ? 'Tap + to add your first transaction.'
                        : 'Try a different search or filter.',
                  );
                }
                final grouped =
                    DateGrouping.group(filtered, (t) => t.date);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH, 0, AppSpacing.screenH, 130),
                  children: [
                    for (final (i, entry) in grouped.entries.indexed) ...[
                      _GroupHeader(
                        bucket: entry.key,
                        total: entry.value.fold(
                            0.0,
                            (a, t) =>
                                a +
                                (t.type == TxnType.expense
                                    ? t.amount
                                    : 0)),
                        currency: cur,
                      ),
                      for (final t in entry.value)
                        _SwipeRow(
                          key: ValueKey(t.id),
                          onDelete: () async {
                            await ref
                                .read(transactionRepoProvider)
                                .delete(t.id);
                            ref.read(dataRevisionProvider.notifier).bump();
                            Haptics.success();
                          },
                          child: TransactionRow(
                            txn: t,
                            currency: cur,
                            onTap: () =>
                                showTransactionDetail(context, ref, t),
                          ),
                        ),
                      // Inline native ad after the first group blends into feed.
                      if (i == 0) const NativeAdCard(),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _Filter { all, expense, income }

extension on _Filter {
  String get label => switch (this) {
        _Filter.all => 'All',
        _Filter.expense => 'Expenses',
        _Filter.income => 'Income',
      };
}

enum _Sort { dateDesc, dateAsc, amountDesc, amountAsc }

extension on _Sort {
  String get label => switch (this) {
        _Sort.dateDesc => 'Newest',
        _Sort.dateAsc => 'Oldest',
        _Sort.amountDesc => 'Highest',
        _Sort.amountAsc => 'Lowest',
      };
}

class _SortButton extends StatelessWidget {
  final _Sort current;
  final ValueChanged<_Sort> onSelected;
  const _SortButton({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<_Sort>(
      initialValue: current,
      onSelected: onSelected,
      tooltip: 'Sort',
      itemBuilder: (context) => [
        for (final s in _Sort.values)
          PopupMenuItem(value: s, child: Text(s.label)),
      ],
      child: Row(
        children: [
          Icon(Icons.swap_vert, size: 18, color: cs.primary),
          const SizedBox(width: 2),
          Text(current.label,
              style: TextStyle(
                  color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Horizontal strip of category chips built from the data; tapping filters.
class _CategoryStrip extends ConsumerWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _CategoryStrip({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(allTransactionsProvider).value ?? const [];
    final cats = (<String>{for (final t in txns) t.category}.toList())..sort();
    if (cats.isEmpty) return const SizedBox(height: AppSpacing.sm);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: const Text('All categories'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final cat in cats)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(cat),
                selected: selected == cat,
                onSelected: (_) => onSelected(cat),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: active ? c.accentSoft : c.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: active ? c.accent : c.hairline),
        ),
        child: Text(label,
            style: AppType.bodySm.copyWith(
              color: active ? c.accent : c.textSecondary,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final DateBucket bucket;
  final double total;
  final String currency;
  const _GroupHeader({
    required this.bucket,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
          top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(bucket.label,
              style: AppType.label.copyWith(color: c.textSecondary)),
          Text('−${Money.format(total, code: currency, compact: true)}',
              style: AppType.caption.copyWith(color: c.textTertiary)),
        ],
      ),
    );
  }
}

/// Swipe-left to reveal + commit a delete. Custom (no Dismissible styling deps).
class _SwipeRow extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onDelete;
  const _SwipeRow({super.key, required this.child, required this.onDelete});

  @override
  State<_SwipeRow> createState() => _SwipeRowState();
}

class _SwipeRowState extends State<_SwipeRow> {
  double _dx = 0;
  static const _max = 88.0;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        setState(() => _dx = (_dx + d.delta.dx).clamp(-_max, 0.0));
      },
      onHorizontalDragEnd: (_) async {
        if (_dx <= -_max * 0.7) {
          setState(() => _dx = -_max);
          await widget.onDelete();
        } else {
          setState(() => _dx = 0);
        }
      },
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: _max,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.expense.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(Icons.delete_outline, color: c.expense),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            transform: Matrix4.translationValues(_dx, 0, 0),
            color: c.background,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
