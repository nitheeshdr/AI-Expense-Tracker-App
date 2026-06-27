import '../../core/data/models.dart';
import '../../core/data/repositories.dart';
import 'groq_client.dart';
import 'prompts.dart';

/// High-level AI assistant facade. Builds a grounded snapshot from the
/// repositories, calls Groq when a key is present, and produces a useful
/// rule-based answer when offline or unconfigured.
class GroqService {
  final GroqClient client;
  final TransactionRepository txnRepo;
  final BudgetRepository budgetRepo;

  GroqService({
    required this.client,
    required this.txnRepo,
    required this.budgetRepo,
  });

  Future<String> ask({
    required String question,
    required List<ChatMessageEntity> history,
    required String currency,
    String? apiKey,
  }) async {
    final snapshot = await _buildSnapshot(currency);

    if (apiKey == null || apiKey.isEmpty) {
      return _offlineAnswer(question, snapshot);
    }

    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': GroqPrompts.system(currency)},
        {'role': 'system', 'content': snapshot.text},
        // last few turns for continuity
        ...history.reversed.take(8).toList().reversed.map((m) => {
              'role': m.role == ChatRole.user ? 'user' : 'assistant',
              'content': m.content,
            }),
        {'role': 'user', 'content': question},
      ];
      return await client.complete(apiKey: apiKey, messages: messages);
    } catch (_) {
      return '${_offlineAnswer(question, snapshot)}\n\n(Offline answer — couldn\'t reach Groq. Check your key/connection in Settings.)';
    }
  }

  Future<_Snapshot> _buildSnapshot(String currency) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);
    final totals = await txnRepo.totals(start, end);
    final cats = await txnRepo.byCategory(start, end);
    final budgets = await budgetRepo.all();
    final overall = budgets
        .where((b) => b.category == 'Overall')
        .fold(0.0, (a, b) => a + b.amount);
    final recent = await txnRepo.all(limit: 8);

    final text = GroqPrompts.snapshot(
      currency: currency,
      income: totals.income,
      expense: totals.expense,
      budget: overall,
      topCategories: cats.take(6).map((c) => (c.category, c.total)).toList(),
      recentMerchants:
          recent.map((t) => (t.merchant, t.amount)).toList(),
    );
    return _Snapshot(
      text: text,
      income: totals.income,
      expense: totals.expense,
      budget: overall,
      topCategories: cats,
    );
  }

  /// Lightweight templated reasoning over the snapshot — keeps the assistant
  /// genuinely useful without a network call.
  String _offlineAnswer(String q, _Snapshot s) {
    final lower = q.toLowerCase();
    final savings = s.income - s.expense;
    String money(double v) => v.toStringAsFixed(0);

    // No real data yet — never fabricate numbers.
    if (s.income == 0 && s.expense == 0 && s.topCategories.isEmpty) {
      return "I don't have any transactions to analyse yet. Import your bank & UPI SMS (Profile → Import from SMS) or add an expense, and I'll give you real insights.";
    }

    if (lower.contains('save') || lower.contains('saving')) {
      final top = s.topCategories.take(2).map((c) => c.category).join(' and ');
      return 'You\'ve saved ${money(savings)} so far this month. Your biggest spend is in $top — trimming those by 15% would add roughly ${money(s.topCategories.take(2).fold(0.0, (a, c) => a + c.total) * 0.15)} back to savings.';
    }
    if (lower.contains('food') ||
        s.topCategories.any((c) => lower.contains(c.category.toLowerCase()))) {
      final match = s.topCategories.firstWhere(
        (c) => lower.contains(c.category.toLowerCase()),
        orElse: () => s.topCategories.isNotEmpty
            ? s.topCategories.first
            : const CategoryTotal('Food', 0),
      );
      return 'You spent ${money(match.total)} on ${match.category} this month.';
    }
    if (lower.contains('budget')) {
      final pct = s.budget <= 0 ? 0 : (s.expense / s.budget * 100).round();
      return 'You\'ve used $pct% of your ${money(s.budget)} monthly budget (${money(s.expense)} spent). ${pct > 90 ? "You're close to the limit — ease off discretionary spends." : "You're on track."}';
    }
    if (lower.contains('summar') || lower.contains('this week') || lower.contains('habit')) {
      return 'This month: income ${money(s.income)}, expenses ${money(s.expense)}, net ${money(savings)}. Top categories: ${s.topCategories.take(3).map((c) => '${c.category} (${money(c.total)})').join(', ')}.';
    }
    return 'Here\'s your snapshot — income ${money(s.income)}, expenses ${money(s.expense)}, net ${money(savings)}. Add your Groq API key in Settings to unlock deeper, conversational analysis.';
  }
}

class _Snapshot {
  final String text;
  final double income;
  final double expense;
  final double budget;
  final List<CategoryTotal> topCategories;
  const _Snapshot({
    required this.text,
    required this.income,
    required this.expense,
    required this.budget,
    required this.topCategories,
  });
}
