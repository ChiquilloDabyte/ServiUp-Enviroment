import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/verification_viewmodel.dart';
import '../../models/enums/user_role.dart';
import '../../models/phone_verification_state.dart';
import '../../utils/phone_number_utils.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class PhoneVerificationView extends ConsumerStatefulWidget {
  const PhoneVerificationView({super.key});

  @override
  ConsumerState<PhoneVerificationView> createState() =>
      _PhoneVerificationViewState();
}

class _PhoneVerificationViewState extends ConsumerState<PhoneVerificationView> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  Timer? _timer;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(phoneVerificationViewModelProvider.notifier).reset();
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  int _remainingSeconds(PhoneVerificationState state) {
    final availableAt = state.resendAvailableAt;
    if (availableAt == null) return 0;
    final remaining = availableAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining + 1 : 0;
  }

  Future<void> _sendCode({bool resend = false}) async {
    try {
      await ref
          .read(phoneVerificationViewModelProvider.notifier)
          .start(_phoneController.text, resend: resend);
    } catch (_) {
      // The ViewModel exposes the translated error in its state.
    }
  }

  Future<void> _confirm() async {
    try {
      await ref
          .read(phoneVerificationViewModelProvider.notifier)
          .confirm(_codeController.text);
    } catch (_) {
      // The ViewModel exposes the translated error in its state.
    }
  }

  Future<void> _syncExistingPhone() async {
    try {
      await ref
          .read(phoneVerificationViewModelProvider.notifier)
          .syncExistingPhone();
    } catch (_) {
      // The ViewModel exposes the translated error in its state.
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
    final profile = ref.watch(currentUserProfileProvider).value;
    final authUser = ref.watch(authStateProvider).value;
    final state = ref.watch(phoneVerificationViewModelProvider);
    final existingAuthPhone = authUser?.phoneNumber;

    if (!_initialized && profile != null) {
      _initialized = true;
      _phoneController.text = localColombianMobile(
        existingAuthPhone ?? profile.phone,
      );
    }

    if (profile?.role != UserRole.provider) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verifica tu celular')),
        body: const Center(
          child: Text('La verificación telefónica es solo para prestadores.'),
        ),
      );
    }

    final remaining = _remainingSeconds(state);
    final showCode =
        state.phase == PhoneVerificationPhase.codeSent ||
        state.phase == PhoneVerificationPhase.verifying;

    return Scaffold(
      appBar: AppBar(title: const Text('Verifica tu celular')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContent(
            maxWidth: 600,
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    state.phase == PhoneVerificationPhase.completed
                        ? Icons.verified_outlined
                        : Icons.phone_android_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.phase == PhoneVerificationPhase.completed
                        ? 'Celular verificado'
                        : 'Confirma tu número',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    state.phase == PhoneVerificationPhase.completed
                        ? 'Ya puedes enviar propuestas y aparecer en el directorio.'
                        : 'Usaremos un único SMS. Tu número será visible en el '
                            'directorio de prestadores cuando quede verificado.',
                    textAlign: TextAlign.center,
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ErrorBanner(message: state.errorMessage!),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  if (state.phase == PhoneVerificationPhase.completed)
                    FilledButton(
                      onPressed: _finish,
                      child: const Text('Continuar'),
                    )
                  else if (showCode) ...[
                    TextFormField(
                      controller: _codeController,
                      enabled: !state.isBusy,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Código de seis dígitos',
                        prefixIcon: Icon(Icons.password_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    FilledButton(
                      onPressed: state.isBusy ? null : _confirm,
                      child: Text(
                        state.isBusy ? 'Verificando...' : 'Verificar código',
                      ),
                    ),
                    TextButton(
                      onPressed:
                          state.isBusy || remaining > 0
                              ? null
                              : () => _sendCode(resend: true),
                      child: Text(
                        remaining > 0
                            ? 'Reenviar en $remaining s'
                            : 'Reenviar código',
                      ),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _phoneController,
                      enabled: !state.isBusy,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Celular',
                        prefixText: '+57 ',
                        prefixIcon: Icon(Icons.phone_outlined),
                        helperText: 'Número móvil colombiano de 10 dígitos.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Al continuar, Firebase enviará y almacenará el número '
                      'para verificarlo y prevenir abuso.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    FilledButton(
                      onPressed: state.isBusy ? null : _sendCode,
                      child: Text(
                        state.isBusy ? 'Enviando...' : 'Enviar código',
                      ),
                    ),
                    if (existingAuthPhone != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      OutlinedButton(
                        onPressed: state.isBusy ? null : _syncExistingPhone,
                        child: Text(
                          'Sincronizar $existingAuthPhone sin otro SMS',
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
