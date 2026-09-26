/// Coordinates banner ad load attempts per ad unit ID across every widget
/// instance that shares it. The banner unit ID is reused on several screens
/// (and Flutter's IndexedStack keeps every visited tab's widgets alive), so
/// multiple `BannerAdCard`s can independently retry at once — each on its
/// own schedule — and their combined request rate for the same ad unit ID
/// is what trips AdMob's own client-side guard ("Too many recently failed
/// requests... you must wait a few seconds"), regardless of how long any
/// single widget waits between its own attempts.
class AdRequestGate {
  AdRequestGate._();
  static final Map<String, DateTime> _lastAttempt = {};
  static const _minGap = Duration(seconds: 15);

  /// True if enough time has passed since the last load attempt for
  /// [adUnitId] across every widget instance, and records this attempt if
  /// so. Callers that get `false` back should wait and check again shortly
  /// rather than loading immediately.
  static bool tryAcquire(String adUnitId) {
    final now = DateTime.now();
    final last = _lastAttempt[adUnitId];
    if (last != null && now.difference(last) < _minGap) return false;
    _lastAttempt[adUnitId] = now;
    return true;
  }
}
