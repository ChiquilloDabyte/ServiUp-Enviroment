import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/auth_viewmodel.dart';
import '../../models/enums/user_role.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _selectedCategories = <String>{};
  File? _avatarFile;
  String? _error;
  UserRole _recoveryRole = UserRole.client;

  @override
  void dispose() {
    _nameController.dispose();
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
      final location =
          await ref.read(locationRepositoryProvider).getCurrentLocation();
      await ref
          .read(userViewModelProvider.notifier)
          .saveProfile(
            user: user,
            name: _nameController.text,
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

  Future<void> _recoverMissingProfile() async {
    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) return;
    setState(() => _error = null);
    try {
      await ref
          .read(userViewModelProvider.notifier)
          .createMissingProfile(
            userId: authUser.uid,
            email: authUser.email ?? '',
            role: _recoveryRole,
          );
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    final isLoading = ref.watch(userViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu perfil')),
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, _) => EmptyState(
                icon: Icons.person_off_outlined,
                title: 'No pudimos cargar tu perfil',
                message: authErrorMessage(error),
              ),
          data: (user) {
            if (user == null) {
              return ResponsiveContent(
                maxWidth: 560,
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Recupera tu perfil',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Tu sesión está activa, pero falta el perfil. '
                        'Selecciona el tipo de cuenta para reconstruirlo.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SegmentedButton<UserRole>(
                        segments: const [
                          ButtonSegment(
                            value: UserRole.client,
                            label: Text('Cliente'),
                            icon: Icon(Icons.person_outline),
                          ),
                          ButtonSegment(
                            value: UserRole.provider,
                            label: Text('Prestador'),
                            icon: Icon(Icons.handyman_outlined),
                          ),
                        ],
                        selected: {_recoveryRole},
                        onSelectionChanged:
                            (roles) =>
                                setState(() => _recoveryRole = roles.first),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: isLoading ? null : _recoverMissingProfile,
                        child: Text(isLoading ? 'Recuperando...' : 'Continuar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: ResponsiveContent(
                maxWidth: 680,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Cuéntanos sobre ti',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Esta información ayuda a generar confianza en cada servicio.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_error != null) ...[
                        ErrorBanner(message: _error!),
                        const SizedBox(height: AppSpacing.gutter),
                      ],
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Semantics(
                                button: true,
                                label: 'Seleccionar foto de perfil',
                                child: InkWell(
                                  onTap: _pickAvatar,
                                  customBorder: const CircleBorder(),
                                  child: CircleAvatar(
                                    radius: 52,
                                    backgroundColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryFixed,
                                    foregroundImage:
                                        _avatarFile != null
                                            ? FileImage(_avatarFile!)
                                            : null,
                                    child:
                                        _avatarFile == null
                                            ? Icon(
                                              Icons.add_a_photo_outlined,
                                              size: 32,
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryFixedVariant,
                                            )
                                            : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Añadir foto',
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Ingresa tu nombre'
                                          : null,
                            ),
                          ],
                        ),
                      ),
                      if (user.role == UserRole.provider) ...[
                        const SizedBox(height: AppSpacing.md),
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'El celular se verificará mediante SMS cuando '
                                'quieras enviar tu primera propuesta.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Categorías de servicio',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Selecciona los trabajos que puedes realizar.',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children:
                                    AppConstants.serviceCategories.map((
                                      category,
                                    ) {
                                      final selected = _selectedCategories
                                          .contains(category);
                                      return FilterChip(
                                        label: Text(category),
                                        selected: selected,
                                        onSelected: (value) {
                                          setState(() {
                                            if (value) {
                                              _selectedCategories.add(category);
                                            } else {
                                              _selectedCategories.remove(
                                                category,
                                              );
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(isLoading ? 'Guardando...' : 'Continuar'),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextButton(
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/home');
                                  }
                                },
                        child: const Text('Explorar por ahora'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
