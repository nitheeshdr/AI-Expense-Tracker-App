import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../services/ads/ad_config.dart';
import '../../../services/ads/ads_manager.dart';
import '../../design/app_theme.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';

/// Inline native ad that blends into feeds. Uses the plugin's medium native
/// template, themed to the app's colors/typography so it reads like a card in
/// the list rather than a jarring banner. Reserves no space until loaded.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _built = false;
  bool _loading = false;
  int _attempts = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    AdsManager.instance.ready.addListener(_kick);
    AdsManager.instance.resumeTick.addListener(_onResume);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_built) return;
    _built = true;
    _kick();
  }

  void _onResume() {
    if (_loaded || _loading) return;
    _attempts = 0;
    _retryTimer?.cancel();
    _kick();
  }

  void _kick() {
    if (mounted && _built && !_loaded && !_loading) _load();
  }

  void _load() {
    if (!AdsManager.instance.isInitialized ||
        AdsManager.instance.isAdFreeActive) {
      return;
    }
    _loading = true;
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
          _loading = false;
          _attempts = 0;
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (identical(_ad, ad)) _ad = null;
          _loading = false;
          debugPrint('Native failed: ${err.code} ${err.message}');
          if (AdsManager.isRetryable(err) && _attempts < 8) {
            _retryTimer?.cancel();
            _retryTimer =
                Timer(AdsManager.retryDelayJittered(_attempts++), _kick);
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    AdsManager.instance.ready.removeListener(_kick);
    AdsManager.instance.resumeTick.removeListener(_onResume);
    _retryTimer?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    if (!_loaded || _ad == null || AdsManager.instance.isAdFreeActive) {
      return const SizedBox.shrink();
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
