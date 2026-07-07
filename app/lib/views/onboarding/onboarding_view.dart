import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/auth_viewmodel.dart';
import '../../models/enums/user_role.dart';
import '../../widgets/error_banner.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _selectedCategories = <String>{};
  File? _avatarFile;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _avatarFile = File(image.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    setState(() => _error = null);

    try {
      final location = await ref.read(locationServiceProvider).getCurrentLocation();
      await ref.read(userViewModelProvider.notifier).saveProfile(
            user: user,
            name: _nameController.text,
            phone: _phoneController.text,
            categories: _selectedCategories.toList(),
            latitude: location.latitude,
            longitude: location.longitude,
            avatarFile: _avatarFile,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    final isLoading = ref.watch(userViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu perfil')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(authErrorMessage(error))),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Sesión no disponible'));
          }

          return SingleChildScrollView(
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
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage:
                            _avatarFile != null ? FileImage(_avatarFile!) : null,
                        child: _avatarFile == null
                            ? const Icon(Icons.camera_alt)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Ingresa tu nombre' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Ingresa tu teléfono' : null,
                  ),
                  if (user.role == UserRole.provider) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Categorías de servicio',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: AppConstants.serviceCategories.map((category) {
                        final selected = _selectedCategories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: Text(isLoading ? 'Guardando...' : 'Continuar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
