import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../core/logger/app_logger.dart';
import '../firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    FlutterError.onError = (details) {
      AppLogger.error('Flutter error', details.exception, details.stack);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('Platform error', error, stack);
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    AppLogger.info('Firebase initialized');
  }
}
