import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/logger/app_logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  Future<void>? _initializationFuture;

  Future<void> initialize() async {
    final existingInitialization = _initializationFuture;
    if (existingInitialization != null) {
      await existingInitialization;
      return;
    }

    final initialization = _initialize();
    _initializationFuture = initialization;

    try {
      await initialization;
    } catch (error, stackTrace) {
      if (identical(_initializationFuture, initialization)) {
        _initializationFuture = null;
      }
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Notification service initialization failed',
      );
      rethrow;
    }
  }

  Future<void> _initialize() async {
    if (kIsWeb) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e, stack) {
      AppLogger.warning('FCM token unavailable', e, stack);
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }

  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();
}
