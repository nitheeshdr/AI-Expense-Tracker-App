import 'dart:io';

import 'package:in_app_update/in_app_update.dart';

/// Checks the Play Store for a newer version and, if one is available,
/// starts a flexible (silent, background-downloaded) in-app update via
/// Google Play Core — https://developer.android.com/guide/playcore/in-app-updates.
/// This only works when the app was installed through Google Play; on a
/// sideloaded APK, an emulator, or with Play services unavailable,
/// `checkForUpdate` throws, which is swallowed here as a no-op.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  bool _checked = false;

  /// Call once per app session (e.g. on home screen start). No-ops on iOS.
  Future<void> checkAndStartFlexibleUpdate() async {
    if (_checked || !Platform.isAndroid) return;
    _checked = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
      }
    } catch (_) {}
  }

  /// Emits install progress; a `downloaded` event means the update is ready
  /// to install via [completeUpdate] (finishes on next app restart either
  /// way, but calling this lets the user apply it immediately).
  Stream<InstallStatus> get installStatus => InAppUpdate.installUpdateListener;

  Future<void> completeUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (_) {}
  }
}
