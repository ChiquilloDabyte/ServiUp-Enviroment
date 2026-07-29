import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/verification_viewmodel.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class EmailVerificationView extends ConsumerStatefulWidget {
  const EmailVerificationView({super.key});

  @override
  ConsumerState<EmailVerificationView> createState() =>
      _EmailVerificationViewState();
}

class _EmailVerificationViewState extends ConsumerState<EmailVerificationView>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _resendAvailableAt;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _resendAvailableAt != null) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh(silent: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  int get _remainingSeconds {
    final availableAt = _resendAvailableAt;
    if (availableAt == null) return 0;
    final remaining = availableAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining + 1 : 0;
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _message = null;
    });
    try {
      await ref.read(emailVerificationViewModelProvider.notifier).resend();
      if (!mounted) return;
      setState(() {
        _resendAvailableAt = DateTime.now().add(const Duration(seconds: 60));
        _message = 'Enviamos un nuevo enlace de verificación.';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = verificationErrorMessage(error));
      }
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _error = null;
        _message = null;
      });
    }
    try {
      final verified =
          await ref.read(emailVerificationViewModelProvider.notifier).refresh();
      if (!mounted || silent) return;
      setState(() {
        _message =
            verified
                ? 'Tu correo quedó verificado.'
                : 'Aún no vemos la verificación. Abre el enlace e intenta de nuevo.';
      });
    } catch (error) {
      if (mounted && !silent) {
        setState(() => _error = verificationErrorMessage(error));
      }
    }
  }

  void _finish() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).value;
    final isVerified = authUser?.emailVerified ?? false;
    final isLoading = ref.watch(emailVerificationViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Verifica tu correo')),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 600,
          alignment: Alignment.center,
          child: SectionCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  isVerified
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isVerified ? 'Correo verificado' : 'Revisa tu bandeja',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isVerified
                      ? 'Ya puedes realizar las acciones que requieren un correo confirmado.'
                      : 'Enviamos un enlace a ${authUser?.email ?? 'tu correo'}. '
                          'Ábrelo y regresa a ServiUp.',
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ErrorBanner(message: _error!),
                ],
                if (_message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_message!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: AppSpacing.md),
                if (isVerified)
                  FilledButton(
                    onPressed: _finish,
                    child: const Text('Continuar'),
                  )
                else ...[
                  FilledButton(
                    onPressed: isLoading ? null : _refresh,
                    child: Text(
                      isLoading ? 'Comprobando...' : 'Ya verifiqué mi correo',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed:
                        isLoading || _remainingSeconds > 0 ? null : _resend,
                    child: Text(
                      _remainingSeconds > 0
                          ? 'Reenviar en $_remainingSeconds s'
                          : 'Reenviar enlace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
