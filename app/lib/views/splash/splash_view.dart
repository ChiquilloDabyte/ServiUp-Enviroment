import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/logger/app_logger.dart';
import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

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
    final syncService = ref.read(providerSyncRepositoryProvider);
    final authRepository = ref.read(authRepositoryProvider);

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

    await authRepository.authStateChanges().first;
    if (!_isActive) return;

    if (authRepository.currentUser != null) {
      await syncService.syncProvidersIfOnline();
    }
    if (!mounted) return;
    if (_bootstrapCancelled) return;

    final user = authRepository.currentUser;
    context.go(user == null ? '/login' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ResponsiveContent(
            maxWidth: 440,
            padding: const EdgeInsets.all(AppSpacing.mobileMargin),
            child: SectionCard(
              radius: AppRadius.xl,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.handyman_rounded,
                      size: 52,
                      color: theme.colorScheme.onPrimaryFixedVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Servicios confiables, cuando los necesitas.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
