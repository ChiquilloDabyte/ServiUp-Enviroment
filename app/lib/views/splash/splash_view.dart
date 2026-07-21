import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../../core/logger/app_logger.dart';
import '../../domain/providers/app_providers.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  bool _bootstrapCancelled = false;

  @override
  void dispose() {
    _bootstrapCancelled = true;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  bool get _isActive => mounted && !_bootstrapCancelled;

  Future<void> _bootstrap() async {
    final notificationService = ref.read(notificationServiceProvider);
    final syncService = ref.read(syncServiceProvider);

    try {
      await notificationService.initialize();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Notification initialization skipped during bootstrap',
        error,
        stackTrace,
      );
    }
    if (!_isActive) return;

    await FirebaseAuth.instance.authStateChanges().first;
    if (!_isActive) return;

    if (FirebaseAuth.instance.currentUser != null) {
      await syncService.syncProvidersIfOnline();
    }
    if (!mounted) return;
    if (_bootstrapCancelled) return;

    final user = FirebaseAuth.instance.currentUser;
    context.go(user == null ? '/login' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.handyman_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
