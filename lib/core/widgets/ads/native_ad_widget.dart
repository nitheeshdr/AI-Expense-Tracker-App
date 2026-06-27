import 'package:flutter/widgets.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_built) return;
    _built = true;
    _load();
  }

  void _load() {
    if (!AdsManager.instance.isInitialized) return;
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
        onAdFailedToLoad: (ad, err) => ad.dispose(),
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
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: c.hairline),
      ),
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
