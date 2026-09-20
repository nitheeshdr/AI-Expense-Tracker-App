import 'package:home_widget/home_widget.dart';

import '../../core/data/repositories.dart';
import '../../core/utils/formatters.dart';

/// Pushes spending data to all of the app's Android home-screen widgets. The
/// accent color itself is no longer pushed — each widget's own layout now
/// resolves `@color/widget_accent` from the app's Material 3 theme (with a
/// values-night variant), so it follows the device's light/dark mode
/// automatically instead of being hardcoded from Dart.
class HomeWidgetService {
  static const _expenseWidget = 'ExpenseWidgetProvider';
  static const _budgetWidget = 'BudgetWidgetProvider';
  static const _netWidget = 'NetWidgetProvider';

  static Future<void> update({
    required TransactionRepository repo,
    required String currency,
    required double monthlyBudget,
  }) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final monthStart = DateTime(now.year, now.month);
      final monthEnd = DateTime(now.year, now.month + 1);

      final today = await repo.totals(todayStart, todayEnd);
      final month = await repo.totals(monthStart, monthEnd);
      final symbol = Money.symbols[currency] ?? '';
      String fmt(double v) =>
          Money.format(v, code: currency, compact: true).replaceAll(symbol, '');

      // --- Today/month spend widget ---
      await HomeWidget.saveWidgetData<String>('today', fmt(today.expense));
      await HomeWidget.saveWidgetData<String>('currency', symbol);
      await HomeWidget.saveWidgetData<String>(
          'month', 'Spent $symbol${fmt(month.expense)}');
      await HomeWidget.saveWidgetData<String>(
          'income', 'Income $symbol${fmt(month.income)}');
      await HomeWidget.updateWidget(androidName: _expenseWidget);

      // --- Budget progress widget ---
      final remaining = monthlyBudget - month.expense;
      final percent = monthlyBudget <= 0
          ? 0
          : ((month.expense / monthlyBudget) * 100).clamp(0, 100).round();
      await HomeWidget.saveWidgetData<String>(
        'budgetHeadline',
        monthlyBudget <= 0
            ? 'Set a budget in the app'
            : '$symbol${fmt(month.expense)} of $symbol${fmt(monthlyBudget)}',
      );
      await HomeWidget.saveWidgetData<String>(
        'budgetRemainingLabel',
        monthlyBudget <= 0
            ? ''
            : remaining >= 0
                ? '$symbol${fmt(remaining)} left'
                : '$symbol${fmt(-remaining)} over budget',
      );
      await HomeWidget.saveWidgetData<String>('budgetPercent', '$percent');
      await HomeWidget.updateWidget(androidName: _budgetWidget);

      // --- Net-this-month hero widget ---
      final net = month.income - month.expense;
      await HomeWidget.saveWidgetData<String>(
          'netValue', '$symbol${fmt(net)}');
      await HomeWidget.saveWidgetData<String>(
          'netIncomeLabel', 'Income $symbol${fmt(month.income)}');
      await HomeWidget.saveWidgetData<String>(
          'netExpenseLabel', 'Expense $symbol${fmt(month.expense)}');
      await HomeWidget.updateWidget(androidName: _netWidget);
    } catch (_) {
      // Widget not added / platform unsupported — ignore.
    }
  }
}
