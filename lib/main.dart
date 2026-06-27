import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/db/app_database.dart';
import 'core/settings/settings.dart';
import 'services/ads/ads_manager.dart';
import 'services/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  // Warm the database (runs migrations + seed on first launch) and hydrate
  // settings before the first frame so the correct theme/route show instantly.
  await AppDatabase.instance.database;
  await container.read(settingsProvider.notifier).load();

  // Initialize AdMob (non-blocking for first frame). Banners/native ads check
  // isInitialized before loading, so this is safe to fire-and-await briefly.
  await AdsManager.instance.init();
  await AppNotifications.instance.init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AiExpenseApp(),
    ),
  );
}
