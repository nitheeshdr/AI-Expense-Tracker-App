import 'package:home_widget/home_widget.dart';

import '../../core/data/repositories.dart';
import '../../core/utils/formatters.dart';

/// Pushes today's / this month's spending + income to the Android home-screen
/// widget, and the app's accent color so the widget matches the app theme.
class HomeWidgetService {
  static const _androidName = 'ExpenseWidgetProvider';

  static Future<void> update({
    required TransactionRepository repo,
    required String currency,
    required int accentColor,
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

      await HomeWidget.saveWidgetData<String>('today', fmt(today.expense));
      await HomeWidget.saveWidgetData<String>('currency', symbol);
      await HomeWidget.saveWidgetData<String>(
          'month', 'Spent $symbol${fmt(month.expense)}');
      await HomeWidget.saveWidgetData<String>(
          'income', 'Income $symbol${fmt(month.income)}');
      // Accent as #AARRGGBB hex for the native side.
      await HomeWidget.saveWidgetData<String>(
          'accent', '#${accentColor.toRadixString(16).padLeft(8, '0')}');
      await HomeWidget.updateWidget(androidName: _androidName);
    } catch (_) {
      // Widget not added / platform unsupported — ignore.
    }
  }
}
