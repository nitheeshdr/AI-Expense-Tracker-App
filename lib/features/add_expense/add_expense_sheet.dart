import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../core/data/categories.dart';
import '../../core/data/models.dart';
import '../../core/design/spacing.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/ads/native_ad_widget.dart';
import '../../core/widgets/category_icon.dart';
import '../../services/categorization/rule_categorizer.dart';
import '../../services/review/review_service.dart';

/// Opens the Add Expense / Add Income / Edit flow as a Material 3 bottom sheet.
Future<void> openAddExpense(
  BuildContext context,
  WidgetRef ref, {
  bool income = false,
  TransactionEntity? edit,
  double? prefillAmount,
  String? prefillMerchant,
}) {
  return showAppSheet<void>(
    context,
    builder: (context) => _AddExpenseSheet(
      income: income,
      edit: edit,
      prefillAmount: prefillAmount,
      prefillMerchant: prefillMerchant,
    ),
  );
}

/// Lets the user photograph or pick a receipt image, runs on-device OCR, and
/// opens the add-expense sheet prefilled with whatever amount/merchant it
/// could read. Falls back to the plain empty sheet if OCR finds nothing
/// usable — scanning is a shortcut, not a hard requirement.
Future<void> openScanReceipt(BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take photo'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  final image =
      await ImagePicker().pickImage(source: source, imageQuality: 85);
  if (image == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  final result = await ref.read(ocrServiceProvider).scan(image.path);
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  if (!context.mounted) return;

  if (result == null) {
    messenger.showSnackBar(const SnackBar(
      content:
          Text("Couldn't read an amount from that receipt — enter it manually."),
    ));
    return openAddExpense(context, ref);
  }
  return openAddExpense(
    context,
    ref,
    prefillAmount: result.amount,
    prefillMerchant: result.merchant,
  );
}

class _AddExpenseSheet extends ConsumerStatefulWidget {
  final bool income;
  final TransactionEntity? edit;
  final double? prefillAmount;
  final String? prefillMerchant;
  const _AddExpenseSheet({
    required this.income,
    this.edit,
    this.prefillAmount,
    this.prefillMerchant,
  });

  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  late TxnType _type = widget.income ? TxnType.income : TxnType.expense;
  String _amount = '';
  late final TextEditingController _merchant = TextEditingController(
      text: widget.edit?.merchant ?? widget.prefillMerchant ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.edit?.note ?? '');
  late String _category =
      widget.edit?.category ?? (widget.income ? 'Salary' : 'Food');
  late final DateTime _date = widget.edit?.date ?? DateTime.now();
  String _method = 'UPI';
  bool get _fromScan => widget.edit == null && widget.prefillAmount != null;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    if (widget.edit != null) {
      final a = widget.edit!.amount;
      _amount = a.toStringAsFixed(a.truncateToDouble() == a ? 0 : 2);
      _type = widget.edit!.type;
      _method = widget.edit!.paymentMethod ?? 'UPI';
    } else if (widget.prefillAmount != null) {
      final a = widget.prefillAmount!;
      _amount = a.toStringAsFixed(a.truncateToDouble() == a ? 0 : 2);
    }
    _merchant.addListener(_autoCategorize);
    if (_fromScan) _autoCategorize();
  }

  void _autoCategorize() {
    if (_isEdit) return;
    final guess = RuleCategorizer.categorize(_merchant.text,
        isIncome: _type == TxnType.income);
    if (guess != 'Miscellaneous' && guess != _category) {
      setState(() => _category = guess);
    }
  }

  @override
  void dispose() {
    _merchant.dispose();
    _note.dispose();
    super.dispose();
  }

  void _tap(String key) {
    Haptics.selection();
    setState(() {
      if (key == 'back') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (key == '.') {
        if (!_amount.contains('.') && _amount.isNotEmpty) _amount += '.';
      } else {
        if (_amount.contains('.') && _amount.split('.')[1].length >= 2) return;
        if (_amount.replaceAll('.', '').length >= 9) return;
        _amount += key;
      }
    });
  }

  double get _value => double.tryParse(_amount) ?? 0;

  Future<void> _save() async {
    if (_value <= 0) return;
    final settings = ref.read(settingsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final base = widget.edit ??
        TransactionEntity(
          amount: _value,
          type: _type,
          category: _category,
          merchant:
              _merchant.text.trim().isEmpty ? _category : _merchant.text.trim(),
          date: _date,
          source: _fromScan ? TxnSource.receipt : TxnSource.manual,
        );
    final txn = base.copyWith(
      amount: _value,
      type: _type,
      category: _category,
      merchant:
          _merchant.text.trim().isEmpty ? _category : _merchant.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      date: _date,
      paymentMethod: _method,
    );
    final isNewManual = !_isEdit;
    await ref.read(transactionRepoProvider).upsert(txn);
    ref.read(dataRevisionProvider.notifier).bump();
    Haptics.success();
    if (mounted) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(
          '${_type == TxnType.income ? 'Income' : 'Expense'} of '
          '${Money.format(_value, code: settings.currency)} saved',
        ),
      ));
    }
    // After a manual (custom) entry, invite the user to review the app.
    if (isNewManual) {
      await ReviewService.instance.requestReview();
    }
    await ref.read(adsManagerProvider).registerActionAndMaybeShow();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currency = ref.watch(settingsProvider).currency;
    final symbol = Money.symbols[currency] ?? '';
    final isIncome = _type == TxnType.income;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SegmentedButton<TxnType>(
              segments: const [
                ButtonSegment(
                    value: TxnType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.south_west)),
                ButtonSegment(
                    value: TxnType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.north_east)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(symbol,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ),
                const SizedBox(width: 4),
                Text(
                  _amount.isEmpty ? '0' : _amount,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final cat in (isIncome
                    ? Categories.incomes
                    : Categories.expenses))
                  _CategoryPick(
                    category: cat.name,
                    selected: _category == cat.name,
                    onTap: () {
                      Haptics.selection();
                      setState(() => _category = cat.name);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _merchant,
            hint: 'Merchant / description',
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final m in ['UPI', 'Credit Card', 'Debit Card', 'Cash'])
                ChoiceChip(
                  label: Text(m),
                  selected: _method == m,
                  onSelected: (_) => setState(() => _method = m),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Keypad(onTap: _tap),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _isEdit
                ? 'Save changes'
                : 'Add ${isIncome ? 'income' : 'expense'}',
            icon: Icons.check,
            onTap: _value > 0 ? _save : null,
          ),
          const SizedBox(height: AppSpacing.md),
          const NativeAdCard(),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _CategoryPick extends StatelessWidget {
  final String category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryPick({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? cs.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CategoryIcon(category: category, size: 50),
            ),
            const SizedBox(height: 4),
            Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _Keypad({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const keys = [
      '1', '2', '3', //
      '4', '5', '6', //
      '7', '8', '9', //
      '.', '0', 'back', //
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.9,
      children: [
        for (final k in keys) _Key(label: k, onTap: () => onTap(k)),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Key({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: label == 'back'
                ? const Icon(Icons.backspace_outlined, size: 22)
                : Text(label,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
