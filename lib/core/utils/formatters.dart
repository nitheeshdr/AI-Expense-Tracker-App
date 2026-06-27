import 'package:intl/intl.dart';

/// Currency + date formatting. Currency code is user-configurable (settings).
class Money {
  Money._();

  static const Map<String, String> symbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AED': 'AED ',
  };

  static String format(double amount, {String code = 'INR', bool compact = false}) {
    final symbol = symbols[code] ?? '';
    if (compact && amount.abs() >= 1000) {
      final f = NumberFormat.compactCurrency(symbol: symbol, decimalDigits: 1);
      return f.format(amount);
    }
    final f = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
    );
    return f.format(amount);
  }

  static String signed(double amount, {String code = 'INR', bool compact = false}) {
    final prefix = amount > 0 ? '+' : (amount < 0 ? '-' : '');
    return '$prefix${format(amount.abs(), code: code, compact: compact)}';
  }
}

class Dates {
  Dates._();

  static String relative(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    if (d.year == now.year) return DateFormat('d MMM').format(d);
    return DateFormat('d MMM yyyy').format(d);
  }

  static String time(DateTime d) => DateFormat('h:mm a').format(d);
  static String dayMonth(DateTime d) => DateFormat('d MMM').format(d);
  static String full(DateTime d) => DateFormat('EEE, d MMM yyyy · h:mm a').format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
}
