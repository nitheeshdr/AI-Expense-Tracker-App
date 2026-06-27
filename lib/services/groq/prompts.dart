/// System prompt + context-builder for the AI assistant. We inject a compact
/// financial snapshot so answers are grounded in the user's real data without
/// shipping every transaction.
class GroqPrompts {
  GroqPrompts._();

  static String system(String currency) => '''
You are "Aria", the friendly, sharp financial assistant inside the AI Expense
Tracker app. You help the user understand spending, budgets, savings and habits.

Rules:
- Be concise and warm. Use short paragraphs and tight bullet lists.
- All amounts are in $currency. Format money with the currency symbol.
- Ground every claim in the SNAPSHOT provided. If data is missing, say so.
- Give specific, actionable suggestions ("cancel X", "cap Y at Z").
- Never invent transactions. Never give regulated investment/tax advice;
  offer general guidance and suggest consulting a professional when relevant.
- Plain text only (no markdown tables); the app renders your text directly.
''';

  /// Compact, token-efficient snapshot of the user's month.
  static String snapshot({
    required String currency,
    required double income,
    required double expense,
    required double budget,
    required List<(String, double)> topCategories,
    required List<(String, double)> recentMerchants,
  }) {
    final cats = topCategories
        .map((c) => '${c.$1}: ${c.$2.toStringAsFixed(0)}')
        .join(', ');
    final merch = recentMerchants
        .map((m) => '${m.$1} ${m.$2.toStringAsFixed(0)}')
        .join('; ');
    final savings = income - expense;
    return '''
SNAPSHOT (this month, $currency):
- Income: ${income.toStringAsFixed(0)}
- Expense: ${expense.toStringAsFixed(0)}
- Net savings: ${savings.toStringAsFixed(0)}
- Monthly budget cap: ${budget.toStringAsFixed(0)}
- Top categories: $cats
- Recent merchants: $merch
''';
  }
}
