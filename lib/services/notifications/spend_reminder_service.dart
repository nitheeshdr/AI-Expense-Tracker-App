import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/data/repositories.dart';
import '../../core/utils/formatters.dart';

const _taskName = 'spend_reminder';
const _uniqueName = 'spend_reminder_periodic';
const _kReminderCount = 'reminder_fire_count';

/// Runs in a separate background isolate WorkManager spins up — no access to
/// the running app's state, so it opens the DB and reads settings directly
/// rather than going through Riverpod providers.
@pragma('vm:entry-point')
void spendReminderCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await _showReminder();
    return true;
  });
}

Future<void> _showReminder() async {
  final prefs = await SharedPreferences.getInstance();
  final currency = prefs.getString('currency') ?? 'INR';
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final monthStart = DateTime(now.year, now.month);
  final monthEnd = DateTime(now.year, now.month + 1);
  final budget = prefs.getDouble('monthlyBudget') ?? 45000;

  final repo = TransactionRepository();
  final today = await repo.totals(todayStart, todayEnd);
  final month = await repo.totals(monthStart, monthEnd);
  final remaining = budget - month.expense;

  // Rotate through a few variants so it doesn't say the exact same thing
  // every time — a persisted counter, not randomness, keeps it deterministic
  // and testable.
  final count = (prefs.getInt(_kReminderCount) ?? 0) + 1;
  await prefs.setInt(_kReminderCount, count);

  final String body;
  if (today.expense <= 0) {
    body = 'No spending logged yet today.';
  } else if (count % 3 == 0 && budget > 0) {
    body = remaining >= 0
        ? '${Money.format(remaining, code: currency, compact: true)} left in this month\'s budget.'
        : '${Money.format(-remaining, code: currency, compact: true)} over this month\'s budget.';
  } else if (count % 3 == 1) {
    body =
        'Today\'s spend: ${Money.format(today.expense, code: currency, compact: true)} so far.';
  } else {
    body =
        'This month so far: ${Money.format(month.expense, code: currency, compact: true)} spent.';
  }

  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(settings: const InitializationSettings(android: android));
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'spend_reminders',
        'Spending reminders',
        description: 'Periodic reminders about your spending',
        importance: Importance.defaultImportance,
      ));
  await plugin.show(
    id: 2000,
    title: 'AI Expense Tracker',
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'spend_reminders',
        'Spending reminders',
        channelDescription: 'Periodic reminders about your spending',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    ),
  );
}

/// Schedules/cancels the periodic spending-reminder notification. WorkManager
/// enforces a 15-minute floor on Android, so this can't go faster than that.
class SpendReminderService {
  SpendReminderService._();
  static final SpendReminderService instance = SpendReminderService._();

  Future<void> init() async {
    await Workmanager().initialize(spendReminderCallbackDispatcher);
  }

  Future<void> schedule(Duration interval) async {
    await Workmanager().registerPeriodicTask(
      _uniqueName,
      _taskName,
      frequency: interval,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(_uniqueName);
  }
}
