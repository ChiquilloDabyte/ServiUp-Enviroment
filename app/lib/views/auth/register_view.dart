import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/viewmodels/auth_viewmodel.dart';
import '../../models/enums/user_role.dart';
import '../../widgets/error_banner.dart';

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
            'Debes aceptar los Términos y Condiciones y la Política de Privacidad. '
      });
      return;
    }

    setState(() => _error = null);
    try {
      await ref.read(authViewModelProvider.notifier).signUp(
            email: _emailController.text,
            password: _passwordController.text,
            role: _role,
          );
      if (mounted) context.go('/onboarding');
    } catch (e) {
      setState(() => _error = authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingresa tu correo' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) => value == null || value.length < 6
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),
                Text('Tipo de cuenta', style: Theme.of(context).textTheme.titleMedium),
                RadioListTile<UserRole>(
                  title: const Text('Cliente'),
                  subtitle: const Text('Publico solicitudes de servicio'),
                  value: UserRole.client,
                  groupValue: _role,
                  onChanged: (value) => setState(() => _role = value!),
                ),
                RadioListTile<UserRole>(
                  title: const Text('Prestador'),
                  subtitle: const Text('Ofrezco servicios'),
                  value: UserRole.provider,
                  groupValue: _role,
                  onChanged: (value) => setState(() => _role = value!),
                ),
                const SizedBox(height: 24),
                CheckBoxListTile(
                  value: _acceptLegalTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptLegalTerms = value ?? false;                     
                    });
                  },
                  controlAfinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'He leído y acepto los Términos y Condiciones y la Política de Privacidad.',
                  ),
                ),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: Text(isLoading ? 'Creando...' : 'Registrarme'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
