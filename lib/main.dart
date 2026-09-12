import 'dart:async';

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

  // Initialize AdMob in the background — it makes a network call to Google's
  // ad servers that can take many seconds (or longer on a slow connection),
  // and previously this was awaited here, blocking the splash screen from
  // ever reaching the first frame. Banners/native ads check isInitialized
  // before loading, so it's safe to let this finish on its own.
  unawaited(AdsManager.instance.init());
  await AppNotifications.instance.init();
  // Must happen here, before the first frame / any screen exists. The
  // `another_telephony` plugin's Android permission-result listener has a
  // bug: once its method channel has been touched even once (e.g. the SMS
  // permission request from onboarding, or the real-time SMS listener), it
  // keeps intercepting *every* later permission-result callback in this
  // process — including ones meant for other plugins — and replies on an
  // already-completed channel result, crashing the app. Resolving the
  // notification permission before anything can call into the SMS plugin
  // avoids that collision entirely.
  await AppNotifications.instance.requestPermission();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AiExpenseApp(),
    ),
  );
}
