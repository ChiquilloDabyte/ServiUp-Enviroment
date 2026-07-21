import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'domain/providers/app_providers.dart';
import 'domain/viewmodels/notification_viewmodel.dart';
import 'domain/viewmodels/offer_viewmodel.dart';
import 'domain/viewmodels/offline_viewmodel.dart';
import 'domain/viewmodels/service_request_viewmodel.dart';

class ServiUpApp extends ConsumerWidget {
  const ServiUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
