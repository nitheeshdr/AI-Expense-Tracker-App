/// Coordinates ad load attempts per ad unit ID across every widget instance
/// that shares it. Banner and native unit IDs are each reused on several
/// screens (and Flutter's IndexedStack keeps every visited tab's widgets
/// alive), so multiple widgets for the same ad unit ID can independently
/// load/retry at once. For banner that combined rate tripped AdMob's
/// client-side guard ("Too many recently failed requests"); for native,
/// several simultaneous `NativeAd.load()` calls for the same ad unit ID
/// (e.g. several ad slots on one long list, plus other tabs' still-mounted
/// slots) came back "Ad failed to load : 0" (internal error) — both
/// confirmed via Ad Inspector / logcat. Gating every attempt through one
/// shared per-ad-unit-ID cooldown keeps the combined rate sane regardless
/// of how many widgets are mounted.
class AdRequestGate {
  AdRequestGate._();
  static final Map<String, DateTime> _lastAttempt = {};

  /// True if enough time has passed since the last load attempt for
  /// [adUnitId] across every widget instance, and records this attempt if
  /// so. Callers that get `false` back should wait and check again shortly
  /// rather than loading immediately. [minGap] differs by ad type: banner
  /// needs ~15s (AdMob's own guard), native only needs enough to avoid
  /// firing several `load()` calls in the same tick (~3s covers a page
  /// with multiple ad slots filling within a couple of seconds of each
  /// other, imperceptible while scrolling).
  static bool tryAcquire(String adUnitId,
      {Duration minGap = const Duration(seconds: 15)}) {
    final now = DateTime.now();
    final last = _lastAttempt[adUnitId];
    if (last != null && now.difference(last) < minGap) return false;
    _lastAttempt[adUnitId] = now;
    return true;
  }
}
