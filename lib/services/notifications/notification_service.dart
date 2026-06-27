import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background tap handler (required top-level for action routing). The app
/// resumes and the foreground [AppNotifications.onAction] handles routing.
@pragma('vm:entry-point')
void notificationBackgroundTap(NotificationResponse response) {}

/// Wrapper over flutter_local_notifications: transaction alerts plus a "live"
/// ongoing notification with quick Add expense / Add income actions, shown on
/// the notification panel and lock screen.
class AppNotifications {
  AppNotifications._();
  static final AppNotifications instance = AppNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _id = 1000;

  /// Set by the UI to route action-button taps ('add_expense' / 'add_income').
  void Function(String actionId)? onAction;

  static const _alertChannel = AndroidNotificationChannel(
    'transactions',
    'Transaction alerts',
    description: 'Notifies you when a new transaction is auto-captured',
    importance: Importance.high,
  );
  static const _liveChannel = AndroidNotificationChannel(
    'live_spending',
    'Live spending',
    description: 'Ongoing today-spending summary with quick actions',
    importance: Importance.low,
  );

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onTap,
        onDidReceiveBackgroundNotificationResponse: notificationBackgroundTap,
      );
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_alertChannel);
      await android?.createNotificationChannel(_liveChannel);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  void _onTap(NotificationResponse r) {
    final id = r.actionId;
    if (id != null) onAction?.call(id);
  }

  /// Returns the action id the app was cold-launched with (if any).
  Future<String?> launchActionId() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse?.actionId;
    }
    return null;
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> show(String title, String body) async {
    if (!_ready) await init();
    if (!_ready) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'transactions',
        'Transaction alerts',
        channelDescription: 'New transaction captured',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      id: _id++ & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static const int _liveId = 42;

  /// Shows/updates the persistent "live" spending notification with quick
  /// Add expense / Add income actions.
  Future<void> showLive(String todaySummary) async {
    if (!_ready) await init();
    if (!_ready) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'live_spending',
        'Live spending',
        channelDescription: 'Today spending summary',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: false,
        visibility: NotificationVisibility.public,
        actions: const [
          AndroidNotificationAction('add_expense', 'Add expense',
              showsUserInterface: true),
          AndroidNotificationAction('add_income', 'Add income',
              showsUserInterface: true),
        ],
      ),
    );
    await _plugin.show(
      id: _liveId,
      title: 'Today\'s spending',
      body: todaySummary,
      notificationDetails: details,
    );
  }
}
