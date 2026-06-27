import 'package:in_app_review/in_app_review.dart';

/// Wraps in-app review + Play Store listing. The Play Store package id should
/// match your published app id.
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _packageName = 'com.aiexpense.ai_expense_tracker';
  final InAppReview _review = InAppReview.instance;

  /// Shows the native in-app review sheet when available.
  Future<void> requestReview() async {
    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
      }
    } catch (_) {}
  }

  /// Opens the Play Store listing directly.
  Future<void> openStoreListing() async {
    try {
      await _review.openStoreListing(appStoreId: _packageName);
    } catch (_) {}
  }
}
