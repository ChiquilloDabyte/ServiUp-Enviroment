import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/viewmodels/auth_viewmodel.dart';
import '../../models/enums/user_role.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.client;
  bool _acceptLegalTerms = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptLegalTerms) {
      setState(() {
        _error =
            'Debes aceptar los Términos y Condiciones y la Política de Privacidad.';
      });
      return;
    }

    setState(() => _error = null);
    try {
      await ref
          .read(authViewModelProvider.notifier)
          .signUp(
            email: _emailController.text,
            password: _passwordController.text,
            role: _role,
          );
      if (mounted) context.go('/onboarding');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewModelProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContent(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Empieza en ServiUp',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Elige cómo quieres usar la plataforma y crea tus credenciales.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          ErrorBanner(message: _error!),
                          const SizedBox(height: AppSpacing.gutter),
                        ],
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Ingresa tu correo'
                                      : null,
                        ),
                        const SizedBox(height: AppSpacing.gutter),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          obscureText: true,
                          validator:
                              (value) =>
                                  value == null || value.length < 6
                                      ? 'Mínimo 6 caracteres'
                                      : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Tipo de cuenta',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        RadioGroup<UserRole>(
                          groupValue: _role,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _role = value);
                            }
                          },
                          child: Column(
                            children: [
                              SectionCard(
                                padding: EdgeInsets.zero,
                                radius: AppRadius.md,
                                child: const RadioListTile<UserRole>(
                                  title: Text('Cliente'),
                                  subtitle: Text(
                                    'Publico solicitudes de servicio',
                                  ),
                                  value: UserRole.client,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              SectionCard(
                                padding: EdgeInsets.zero,
                                radius: AppRadius.md,
                                child: const RadioListTile<UserRole>(
                                  title: Text('Prestador'),
                                  subtitle: Text('Ofrezco servicios'),
                                  value: UserRole.provider,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _acceptLegalTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptLegalTerms = value ?? false;

                              if (_acceptLegalTerms) {
                                _error = null;
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('He leído y acepto los '),
                              _LegalLink(
                                label: 'Términos y Condiciones',
                                onTap: () => context.push('/terms'),
                              ),
                              const Text(' y la '),
                              _LegalLink(
                                label: 'Política de Privacidad',
                                onTap: () => context.push('/privacy'),
                              ),
                              const Text('.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: Text(isLoading ? 'Creando...' : 'Registrarme'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            decoration: TextDecoration.underline,
            decorationColor: color,
          ),
        ),
      ),
    );
  }
}
