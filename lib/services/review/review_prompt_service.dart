import 'package:shared_preferences/shared_preferences.dart';

/// Decides when to surface the in-app "enjoying the app?" review prompt, so
/// only engaged users are asked and nobody gets nagged. Criteria: the app has
/// been installed for a few days, the user has logged a handful of
/// transactions, and enough time has passed since they were last asked (or
/// they haven't been asked before) — unless they said not to ask again.
class ReviewPromptService {
  ReviewPromptService._();
  static final ReviewPromptService instance = ReviewPromptService._();

  static const _kFirstSeen = 'review_first_seen_ms';
  static const _kLastPrompt = 'review_last_prompt_ms';
  static const _kNever = 'review_never_ask';

  static const _minDaysInstalled = 3;
  static const _minTransactions = 6;
  static const _minDaysBetweenPrompts = 21;

  static const _day = Duration(days: 1);

  Future<bool> shouldPrompt(int transactionCount) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kNever) ?? false) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final firstSeen = prefs.getInt(_kFirstSeen);
    if (firstSeen == null) {
      // First time we've checked — start the clock, but don't ask yet.
      await prefs.setInt(_kFirstSeen, now);
      return false;
    }

    if (now - firstSeen < _minDaysInstalled * _day.inMilliseconds) {
      return false;
    }
    if (transactionCount < _minTransactions) return false;

    final lastPrompt = prefs.getInt(_kLastPrompt);
    if (lastPrompt != null &&
        now - lastPrompt < _minDaysBetweenPrompts * _day.inMilliseconds) {
      return false;
    }
    return true;
  }

  Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastPrompt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> markNeverAskAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNever, true);
  }
}
