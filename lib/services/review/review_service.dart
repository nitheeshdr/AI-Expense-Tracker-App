import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

/// Wraps in-app review + the Play Store listing.
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.setupsworks.aiexpensetracker';

  final InAppReview _review = InAppReview.instance;

  /// Shows the native in-app review sheet when available. That API only
  /// works when the app was installed via the Play Store, so on a sideloaded
  /// / test build (or if Play Core declines to show one — it's quota-limited
  /// even on Play) we fall back to opening the Play Store listing directly,
  /// so tapping "Rate the app" always visibly does something.
  Future<void> requestReview() async {
    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
        return;
      }
    } catch (_) {}
    await openStoreListing();
  }

  /// Opens the Play Store listing. `in_app_review`'s own
  /// `openStoreListing(appStoreId:)` is iOS-only (that param is an App
  /// Store numeric id, not an Android package name) — on Android it just
  /// launches the device's default handler for the listing, so we do that
  /// directly with the real Play Store URL.
  Future<void> openStoreListing() async {
    final uri = Uri.parse(_playStoreUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
