import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Owns Firebase init, Crashlytics error capture and the shared Analytics
/// instance. Crash reports and usage events only — no transaction/financial
/// data is ever sent, keeping the on-device-data promise in onboarding.
class AppFirebase {
  AppFirebase._();

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver routeObserver =
      FirebaseAnalyticsObserver(analytics: analytics);

  static Future<void> init() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Route uncaught Flutter framework errors (widget build/layout/paint) to
    // Crashlytics instead of just the debug console.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Route uncaught errors outside the Flutter framework (async gaps, etc).
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
