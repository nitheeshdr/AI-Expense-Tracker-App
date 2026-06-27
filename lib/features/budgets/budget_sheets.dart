import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/categories.dart';
import '../../core/data/models.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/pressable.dart';

/// Create/edit a category (or overall) budget.
Future<void> showBudgetEditor(
  BuildContext context,
  WidgetRef ref, {
  BudgetEntity? existing,
}) {
  return showAppSheet<void>(
    context,
    builder: (context) => _BudgetEditor(existing: existing),
  );
}

class _BudgetEditor extends ConsumerStatefulWidget {
  final BudgetEntity? existing;
  const _BudgetEditor({this.existing});

  @override
  ConsumerState<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends ConsumerState<_BudgetEditor> {
  late String _category = widget.existing?.category ?? 'Food';
  late final TextEditingController _amount = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.amount.toStringAsFixed(0)
          : '');

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text) ?? 0;
    if (amount <= 0) return;
    final budget = BudgetEntity(
      id: widget.existing?.id,
      category: _category,
      amount: amount,
    );
    await ref.read(budgetRepoProvider).upsert(budget);
    ref.read(dataRevisionProvider.notifier).bump();
    if (mounted) Navigator.of(context).pop();
    await ref.read(adsManagerProvider).registerActionAndMaybeShow();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
              title: widget.existing == null ? 'New budget' : 'Edit budget',
              subtitle: 'Pick a category and set a monthly cap.'),
          Text('CATEGORY',
              style: AppType.label.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final cat in Categories.expenses)
                  Pressable(
                    onTap: () => setState(() => _category = cat.name),
                    child: Container(
                      width: 72,
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _category == cat.name
                                    ? c.accent
                                    : const Color(0x00000000),
                                width: 2,
                              ),
                            ),
                            child: CategoryIcon(category: cat.name, size: 52),
                          ),
                          const SizedBox(height: 4),
                          Text(cat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.caption.copyWith(
                                  color: _category == cat.name
                                      ? c.accent
                                      : c.textTertiary)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _amount,
            label: 'MONTHLY LIMIT',
            hint: '0',
            leadingEmoji: '🎯',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (widget.existing != null) ...[
                Expanded(
                  child: AppButton(
                    label: 'Delete',
                    kind: AppButtonKind.ghost,
                    onTap: () async {
                      final nav = Navigator.of(context);
                      await ref
                          .read(budgetRepoProvider)
                          .delete(widget.existing!.id);
                      ref.read(dataRevisionProvider.notifier).bump();
                      if (mounted) nav.pop();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                flex: 2,
                child: AppButton(label: 'Save budget', onTap: _save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Create/edit a savings goal.
Future<void> showGoalEditor(
  BuildContext context,
  WidgetRef ref, {
  SavingsGoalEntity? existing,
}) {
  return showAppSheet<void>(
    context,
    builder: (context) => _GoalEditor(existing: existing),
  );
}

class _GoalEditor extends ConsumerStatefulWidget {
  final SavingsGoalEntity? existing;
  const _GoalEditor({this.existing});

  @override
  ConsumerState<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends ConsumerState<_GoalEditor> {
  late final _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _target = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.target.toStringAsFixed(0)
          : '');
  late final _saved = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.saved.toStringAsFixed(0)
          : '');

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final target = double.tryParse(_target.text) ?? 0;
    if (_name.text.trim().isEmpty || target <= 0) return;
    final goal = SavingsGoalEntity(
      id: widget.existing?.id,
      name: _name.text.trim(),
      target: target,
      saved: double.tryParse(_saved.text) ?? 0,
      deadline: widget.existing?.deadline,
    );
    await ref.read(savingsRepoProvider).upsert(goal);
    ref.read(dataRevisionProvider.notifier).bump();
    if (mounted) Navigator.of(context).pop();
    await ref.read(adsManagerProvider).registerActionAndMaybeShow();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
              title:
                  widget.existing == null ? 'New savings goal' : 'Edit goal',
              subtitle: 'Name it and set a target to save toward.'),
          AppTextField(
              controller: _name,
              label: 'GOAL NAME',
              hint: 'e.g. Goa Trip',
              leadingEmoji: '🏖️'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
              controller: _target,
              label: 'TARGET AMOUNT',
              hint: '0',
              leadingEmoji: '🎯',
              keyboardType: TextInputType.number),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
              controller: _saved,
              label: 'ALREADY SAVED',
              hint: '0',
              leadingEmoji: '💰',
              keyboardType: TextInputType.number),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (widget.existing != null) ...[
                Expanded(
                  child: AppButton(
                    label: 'Delete',
                    kind: AppButtonKind.ghost,
                    onTap: () async {
                      final nav = Navigator.of(context);
                      await ref
                          .read(savingsRepoProvider)
                          .delete(widget.existing!.id);
                      ref.read(dataRevisionProvider.notifier).bump();
                      if (mounted) nav.pop();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                flex: 2,
                child: AppButton(label: 'Save goal', onTap: _save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
