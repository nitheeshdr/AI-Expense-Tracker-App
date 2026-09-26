import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../services/ads/ad_config.dart';
import '../../../services/ads/ad_request_gate.dart';
import '../../../services/ads/ads_manager.dart';
import '../../design/app_theme.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';

/// Inline native ad that blends into feeds. Uses the plugin's medium native
/// template, themed to the app's colors/typography so it reads like a card in
/// the list rather than a jarring banner. Reserves no space until loaded, and
/// only requests an ad once this slot actually scrolls into view — several
/// ad slots on one long page (or on other tabs kept alive underneath this
/// one) all requesting the moment the page builds is what caused
/// simultaneous "Ad failed to load : 0" internal errors for the shared
/// native ad unit ID.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_requested || info.visibleFraction <= 0) return;
    _requested = true;
    _load();
  }

  void _load() {
    if (!AdsManager.instance.isInitialized ||
        AdsManager.instance.isAdFreeActive) {
      return;
    }
    // The same native ad unit ID is reused on several screens, and several
    // slots can become visible at once (e.g. a fast scroll past 2-3 ad
    // positions, or another tab's slots still mounted underneath this one).
    // Gate every attempt through one shared cooldown per ad unit ID so
    // simultaneous `NativeAd.load()` calls for the same ID don't trip
    // AdMob's own internal error for firing too many at once.
    if (!AdRequestGate.tryAcquire(AdConfig.nativeUnit,
        minGap: const Duration(seconds: 3))) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _load();
      });
      return;
    }
    final c = AppTheme.of(context);
    final ad = NativeAd(
      adUnitId: AdConfig.nativeUnit,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: c.surface,
        cornerRadius: AppRadii.lg,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFFFFFFF),
          backgroundColor: c.accent,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: c.textPrimary,
          style: NativeTemplateFontStyle.bold,
          size: 16,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: c.textSecondary,
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: c.textTertiary,
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          // A single failed load previously left this slot empty forever —
          // retry as long as the widget is still on screen. Meta Audience
          // Network (which rejected fast reloads outright) is no longer in
          // the mediation stack, so AdMob Network alone can retry quickly.
          Future.delayed(const Duration(seconds: 8), () {
            if (mounted) _load();
          });
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    if (!_loaded || _ad == null || AdsManager.instance.isAdFreeActive) {
      // A near-zero-size placeholder still reserves no visible space (same
      // as before), but gives VisibilityDetector something to measure so it
      // can tell when this slot scrolls into the viewport.
      return VisibilityDetector(
        key: Key('native_ad_slot_${identityHashCode(this)}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: const SizedBox(height: 1),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, 0, 2),
            child: Text('SPONSORED · AD',
                style: AppType.caption
                    .copyWith(color: c.textTertiary, fontSize: 9)),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 300, maxHeight: 360),
            child: AdWidget(ad: _ad!),
          ),
        ],
      ),
    );
  }
}
