import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/models.dart';
import '../core/data/repositories.dart';
import '../core/settings/settings.dart';
import '../services/ads/ads_manager.dart';
import '../services/groq/groq_client.dart';
import '../services/groq/groq_service.dart';
import '../services/integrations/integrations.dart';

// --- Repositories ---
final transactionRepoProvider =
    Provider<TransactionRepository>((ref) => TransactionRepository());
final budgetRepoProvider =
    Provider<BudgetRepository>((ref) => BudgetRepository());
final savingsRepoProvider =
    Provider<SavingsRepository>((ref) => SavingsRepository());
final chatRepoProvider = Provider<ChatRepository>((ref) => ChatRepository());

// --- Services ---
final groqClientProvider = Provider<GroqClient>((ref) => GroqClient());
final groqServiceProvider = Provider<GroqService>((ref) => GroqService(
      client: ref.watch(groqClientProvider),
      txnRepo: ref.watch(transactionRepoProvider),
      budgetRepo: ref.watch(budgetRepoProvider),
    ));

// Integration stubs (swap impls in later phases without touching consumers).
final smsReaderProvider = Provider<SmsReader>((ref) => StubSmsReader());
final ocrServiceProvider = Provider<OcrService>((ref) => StubOcrService());
final biometricProvider =
    Provider<BiometricService>((ref) => StubBiometricService());
final notificationProvider =
    Provider<NotificationService>((ref) => StubNotificationService());
final adsProvider = Provider<AdsService>((ref) => StubAdsService());

/// Real AdMob manager (singleton). Used by ad widgets + interstitial/rewarded
/// triggers across the app.
final adsManagerProvider = Provider<AdsManager>((ref) => AdsManager.instance);

/// Bumped whenever transactions/budgets/goals change so screens re-fetch.
/// Simple, explicit invalidation that keeps every screen in sync.
class DataRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final dataRevisionProvider =
    NotifierProvider<DataRevision, int>(DataRevision.new);

// --- Month range helper used across dashboard/budgets/AI ---
({DateTime start, DateTime end}) currentMonthRange() {
  final now = DateTime.now();
  return (start: DateTime(now.year, now.month), end: DateTime(now.year, now.month + 1));
}

/// Resolves the current Groq key from secure storage (null when unset).
final groqKeyProvider = FutureProvider<String?>((ref) async {
  // depend on settings so a key change re-reads
  ref.watch(settingsProvider);
  return ref.read(settingsProvider.notifier).groqKey();
});

/// Convenience aggregate the dashboard reads.
class MonthSummary {
  final double income;
  final double expense;
  final double todayExpense;
  final double totalExpense;
  final List<CategoryTotal> byCategory;
  final List<CategoryTotal> topMerchants;
  final List<DayTotal> daily;
  final double lastMonthExpense;
  const MonthSummary({
    required this.income,
    required this.expense,
    required this.todayExpense,
    required this.totalExpense,
    required this.byCategory,
    required this.topMerchants,
    required this.daily,
    required this.lastMonthExpense,
  });
  double get savings => income - expense;
  double get net => income - expense;

  /// Percent change in spend vs last month (null when last month had none).
  double? get expenseChangePct {
    if (lastMonthExpense <= 0) return null;
    return (expense - lastMonthExpense) / lastMonthExpense * 100;
  }
}

final monthSummaryProvider = FutureProvider<MonthSummary>((ref) async {
  ref.watch(dataRevisionProvider);
  final repo = ref.watch(transactionRepoProvider);
  final range = currentMonthRange();
  final now = DateTime.now();
  final lastStart = DateTime(now.year, now.month - 1);
  final lastEnd = DateTime(now.year, now.month);
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final totals = await repo.totals(range.start, range.end);
  final todayTotals = await repo.totals(todayStart, todayEnd);
  final allTime = await repo.totalExpense();
  final cats = await repo.byCategory(range.start, range.end);
  final merchants = await repo.topMerchants(range.start, range.end);
  final daily = await repo.dailyExpense(30);
  final lastTotals = await repo.totals(lastStart, lastEnd);
  return MonthSummary(
    income: totals.income,
    expense: totals.expense,
    todayExpense: todayTotals.expense,
    totalExpense: allTime,
    byCategory: cats,
    topMerchants: merchants,
    daily: daily,
    lastMonthExpense: lastTotals.expense,
  );
});

final recentTransactionsProvider =
    FutureProvider<List<TransactionEntity>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.watch(transactionRepoProvider).all(limit: 6);
});

final allTransactionsProvider =
    FutureProvider<List<TransactionEntity>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.watch(transactionRepoProvider).all();
});

final subscriptionsProvider =
    FutureProvider<List<SubscriptionItem>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.watch(transactionRepoProvider).subscriptions();
});

final budgetsProvider = FutureProvider<List<BudgetEntity>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.watch(budgetRepoProvider).all();
});

final savingsGoalsProvider =
    FutureProvider<List<SavingsGoalEntity>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.watch(savingsRepoProvider).all();
});
