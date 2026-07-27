import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'domain/providers/app_providers.dart';
import 'domain/viewmodels/chat_viewmodel.dart';
import 'domain/viewmodels/notification_viewmodel.dart';
import 'domain/viewmodels/offer_viewmodel.dart';
import 'domain/viewmodels/offline_viewmodel.dart';
import 'domain/viewmodels/service_request_viewmodel.dart';

class ServiUpApp extends ConsumerStatefulWidget {
  const ServiUpApp({super.key});

  @override
  ConsumerState<ServiUpApp> createState() => _ServiUpAppState();
}

class _ServiUpAppState extends ConsumerState<ServiUpApp> {
  StreamSubscription<RemoteMessage>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    final service = ref.read(notificationServiceProvider);
    _notificationSubscription = service.onMessageOpenedApp.listen(
      _openNotification,
    );
    service.getInitialMessage().then((message) {
      if (message != null) _openNotification(message);
    });
  }

  void _openNotification(RemoteMessage message) {
    final chatId = message.data['chatId'];
    final requestId = message.data['requestId'];
    final router = ref.read(routerProvider);
    if (chatId is String && chatId.isNotEmpty) {
      router.push('/chats/$chatId');
    } else if (requestId is String && requestId.isNotEmpty) {
      router.push('/requests/$requestId');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncListenerProvider);
    ref.listen(authStateProvider, (previous, next) {
      final previousUserId = previous?.value?.uid;
      final nextUserId = next.value?.uid;
      if (previousUserId == nextUserId) return;

      ref.invalidate(serviceRequestViewModelProvider);
      ref.invalidate(clientRequestsProvider);
      ref.invalidate(openRequestsProvider);
      ref.invalidate(requestDetailProvider);
      ref.invalidate(nearbyRequestsProvider);
      ref.invalidate(providerActiveJobsProvider);
      ref.invalidate(offerViewModelProvider);
      ref.invalidate(requestOffersProvider);
      ref.invalidate(providerOffersProvider);
      ref.invalidate(chatViewModelProvider);
      ref.invalidate(chatDetailProvider);
      ref.invalidate(chatMessagesProvider);
      ref.invalidate(chatMessagePageProvider);
      ref.invalidate(userChatsProvider);
      ref.invalidate(chatOffersProvider);
      ref.invalidate(userNotificationsProvider);
    });
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
