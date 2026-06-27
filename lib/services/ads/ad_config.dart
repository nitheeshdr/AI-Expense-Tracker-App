import 'dart:io';

/// Central place for AdMob unit IDs and global ad behavior.
///
/// Ships with Google's official **test** ad units so ads render immediately
/// and safely. To go live: set [useTestAds] to `false` and paste your real
/// AdMob unit IDs below. Never click your own live ads — it violates AdMob
/// policy and can get the account banned.
class AdConfig {
  AdConfig._();

  /// Flip to true to use Google's test ad units while developing.
  static const bool useTestAds = false;

  // --- Google's official test unit IDs (safe to ship while testing) ---
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/9214589741';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2435281174';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';
  static const _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const _testNativeIos = 'ca-app-pub-3940256099942544/3986624511';

  // --- Real production unit IDs (Android). iOS reuses them since this build
  //     targets Android; add separate iOS units if you ship to iOS. ---
  static const _prodBannerAndroid = 'ca-app-pub-6621171335214437/8858116499';
  static const _prodBannerIos = 'ca-app-pub-6621171335214437/8858116499';
  static const _prodInterstitialAndroid =
      'ca-app-pub-6621171335214437/2521984455';
  static const _prodInterstitialIos = 'ca-app-pub-6621171335214437/2521984455';
  static const _prodRewardedAndroid = 'ca-app-pub-6621171335214437/6231953156';
  static const _prodRewardedIos = 'ca-app-pub-6621171335214437/6231953156';
  static const _prodNativeAndroid = 'ca-app-pub-6621171335214437/8895821116';
  static const _prodNativeIos = 'ca-app-pub-6621171335214437/8895821116';

  static bool get _android => Platform.isAndroid;

  static String _pick(String testA, String testI, String prodA, String prodI) {
    if (useTestAds) return _android ? testA : testI;
    return _android ? prodA : prodI;
  }

  static String get bannerUnit => _pick(
      _testBannerAndroid, _testBannerIos, _prodBannerAndroid, _prodBannerIos);
  static String get interstitialUnit => _pick(_testInterstitialAndroid,
      _testInterstitialIos, _prodInterstitialAndroid, _prodInterstitialIos);
  static String get rewardedUnit => _pick(_testRewardedAndroid,
      _testRewardedIos, _prodRewardedAndroid, _prodRewardedIos);
  static String get nativeUnit => _pick(
      _testNativeAndroid, _testNativeIos, _prodNativeAndroid, _prodNativeIos);

  /// Show an interstitial at most once every N qualifying actions, and never
  /// more often than [interstitialMinGap]. Tuned for higher fill while staying
  /// within AdMob's UX expectations (avoid back-to-back full-screen ads).
  static const int interstitialEveryNActions = 2;
  static const Duration interstitialMinGap = Duration(seconds: 45);
}
