import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../firebase_options.dart';
import '../notifications/notification_service.dart';

/// Runs in a background isolate when a push arrives while the app is
/// backgrounded/terminated. Android already auto-displays the notification
/// payload in that case, so this only needs to re-init Firebase for the
/// isolate — no extra work required unless the app starts sending data-only
/// messages later.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Receives Cloud Messaging pushes — e.g. announcements composed and sent
/// straight from the Firebase Console's Cloud Messaging campaigns, with no
/// backend required. Foreground messages are shown as a local notification;
/// background/terminated ones are handled by the OS automatically as long as
/// the console message includes a notification (not just data) payload.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      AppNotifications.instance.showRemote(
        notification.title ?? 'AI Expense Tracker',
        notification.body ?? '',
      );
    });
  }

  /// The token Cloud Messaging uses to target this install directly (for
  /// single-device testing from the Firebase Console's "Send test message").
  /// Not persisted anywhere — this app has no backend to send it to.
  Future<String?> debugToken() => FirebaseMessaging.instance.getToken();
}
