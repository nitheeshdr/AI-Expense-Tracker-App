import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../db/app_database.dart';
import 'models.dart';

/// Read/write access to transactions plus the aggregate queries that power the
/// dashboard and analytics. All amounts are stored in the user's base currency.
class TransactionRepository {
  Future<List<TransactionEntity>> all({int? limit}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('transactions',
        orderBy: 'date DESC', limit: limit);
    return rows.map(TransactionEntity.fromMap).toList();
  }

  Future<List<TransactionEntity>> inRange(DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return rows.map(TransactionEntity.fromMap).toList();
  }

  Future<void> upsert(TransactionEntity t) async {
    final db = await AppDatabase.instance.database;
    await db.insert('transactions', t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Sum of expenses (positive) and income for a date range.
  Future<({double income, double expense})> totals(
      DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT type, COALESCE(SUM(amount),0) AS total
      FROM transactions
      WHERE date >= ? AND date < ?
      GROUP BY type
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    double income = 0, expense = 0;
    for (final r in rows) {
      final total = (r['total'] as num).toDouble();
      if (r['type'] == 'income') income = total;
      if (r['type'] == 'expense') expense = total;
    }
    return (income: income, expense: expense);
  }

  Future<List<CategoryTotal>> byCategory(DateTime start, DateTime end,
      {TxnType type = TxnType.expense}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT category, COALESCE(SUM(amount),0) AS total
      FROM transactions
      WHERE type = ? AND date >= ? AND date < ?
      GROUP BY category
      ORDER BY total DESC
    ''', [type.name, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    return rows
        .map((r) => CategoryTotal(r['category'] as String,
            (r['total'] as num).toDouble()))
        .toList();
  }

  /// Detected subscriptions / autopay bills: recurring expense merchants in
  /// subscription-like categories, or any merchant that recurs (2+ times).
  Future<List<SubscriptionItem>> subscriptions() async {
    final db = await AppDatabase.instance.database;
    // Only genuine subscription / autopay categories — not every repeated merchant.
    const cats =
        "('OTT','Subscription','Internet','Mobile','Insurance','EMI','Loans')";
    final rows = await db.rawQuery('''
      SELECT merchant, category,
             AVG(amount) AS amt, MAX(date) AS last, COUNT(*) AS cnt
      FROM transactions
      WHERE type = 'expense' AND category IN $cats
      GROUP BY merchant
      ORDER BY amt DESC
    ''');
    return rows
        .map((r) => SubscriptionItem(
              merchant: r['merchant'] as String,
              category: r['category'] as String,
              amount: (r['amt'] as num).toDouble(),
              count: (r['cnt'] as num).toInt(),
              lastDate:
                  DateTime.fromMillisecondsSinceEpoch(r['last'] as int),
            ))
        .toList();
  }

  /// All-time total expense (across every transaction).
  Future<double> totalExpense() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
        "SELECT COALESCE(SUM(amount),0) AS total FROM transactions WHERE type = 'expense'");
    return (rows.first['total'] as num).toDouble();
  }

  /// Top expense merchants for a date range, by total spend.
  Future<List<CategoryTotal>> topMerchants(DateTime start, DateTime end,
      {int limit = 5}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT merchant, COALESCE(SUM(amount),0) AS total, COUNT(*) AS cnt
      FROM transactions
      WHERE type = 'expense' AND date >= ? AND date < ?
      GROUP BY merchant
      ORDER BY total DESC
      LIMIT ?
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch, limit]);
    return rows
        .map((r) =>
            CategoryTotal(r['merchant'] as String, (r['total'] as num).toDouble()))
        .toList();
  }

  Future<double> spentInCategory(
      String category, DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(amount),0) AS total FROM transactions
      WHERE type = 'expense' AND category = ? AND date >= ? AND date < ?
    ''', [category, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    return (rows.first['total'] as num).toDouble();
  }

  /// Daily expense totals across [days], oldest-first, zero-filled.
  Future<List<DayTotal>> dailyExpense(int days) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final rows = await db.rawQuery('''
      SELECT date, amount FROM transactions
      WHERE type = 'expense' AND date >= ?
    ''', [start.millisecondsSinceEpoch]);

    final buckets = <int, double>{};
    for (var i = 0; i < days; i++) {
      buckets[i] = 0;
    }
    for (final r in rows) {
      final d = DateTime.fromMillisecondsSinceEpoch(r['date'] as int);
      final idx = DateTime(d.year, d.month, d.day).difference(start).inDays;
      if (idx >= 0 && idx < days) {
        buckets[idx] = buckets[idx]! + (r['amount'] as num).toDouble();
      }
    }
    return [
      for (var i = 0; i < days; i++)
        DayTotal(start.add(Duration(days: i)), buckets[i]!),
    ];
  }
}

class BudgetRepository {
  Future<List<BudgetEntity>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('budgets', orderBy: 'created_at ASC');
    return rows.map(BudgetEntity.fromMap).toList();
  }

  Future<void> upsert(BudgetEntity b) async {
    final db = await AppDatabase.instance.database;
    await db.insert('budgets', b.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}

class SavingsRepository {
  Future<List<SavingsGoalEntity>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('savings_goals', orderBy: 'created_at ASC');
    return rows.map(SavingsGoalEntity.fromMap).toList();
  }

  Future<void> upsert(SavingsGoalEntity g) async {
    final db = await AppDatabase.instance.database;
    await db.insert('savings_goals', g.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }
}

class ChatRepository {
  Future<List<ChatMessageEntity>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('ai_messages', orderBy: 'created_at ASC');
    return rows.map(ChatMessageEntity.fromMap).toList();
  }

  Future<void> add(ChatMessageEntity m) async {
    final db = await AppDatabase.instance.database;
    await db.insert('ai_messages', m.toMap());
  }

  Future<void> clear() async {
    final db = await AppDatabase.instance.database;
    await db.delete('ai_messages');
  }
}
