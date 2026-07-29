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
import '../../models/user_model.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  final Set<String> _categories = {};

  String? _loadedUserId;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initialize(UserModel user) {
    if (_loadedUserId == user.id) return;
    _loadedUserId = user.id;
    _nameController.text = user.name;
    _categories
      ..clear()
      ..addAll(user.serviceCategories);
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (image == null || !mounted) return;
      setState(() => _selectedImage = File(image.path));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }

  Future<void> _save(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;
    if (user.role == UserRole.provider && _categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una categoría de servicio.'),
        ),
      );
      return;
    }

    try {
      await ref
          .read(userViewModelProvider.notifier)
          .saveProfile(
            user: user,
            name: _nameController.text,
            categories:
                user.role == UserRole.provider
                    ? _categories.toList()
                    : const [],
            latitude: user.latitude,
            longitude: user.longitude,
            avatarFile: _selectedImage,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    final saving = ref.watch(userViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, _) => Center(child: Text(authErrorMessage(error))),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuario no encontrado'));
          }
          _initialize(user);

          return ResponsiveContent(
            maxWidth: 720,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Center(
                  child: Semantics(
                    button: true,
                    label: 'Seleccionar foto de perfil',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(64),
                      onTap: saving ? null : _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 52,
                            foregroundImage: _avatarImage(user),
                            child:
                                _avatarImage(user) == null
                                    ? const Icon(Icons.person_outline, size: 48)
                                    : null,
                          ),
                          CircleAvatar(
                            radius: 18,
                            child: const Icon(Icons.camera_alt_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          enabled: !saving,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Ingresa tu nombre.'
                                      : null,
                        ),
                        if (user.role == UserRole.provider) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Categorías de servicio',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xxs,
                            children:
                                AppConstants.serviceCategories.map((category) {
                                  return FilterChip(
                                    label: Text(category),
                                    selected: _categories.contains(category),
                                    onSelected:
                                        saving
                                            ? null
                                            : (selected) {
                                              setState(() {
                                                if (selected) {
                                                  _categories.add(category);
                                                } else {
                                                  _categories.remove(category);
                                                }
                                              });
                                            },
                                  );
                                }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: saving ? null : () => _save(user),
                  icon:
                      saving
                          ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Guardando...' : 'Guardar cambios'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ImageProvider? _avatarImage(UserModel user) {
    if (_selectedImage != null) return FileImage(_selectedImage!);
    if (user.photoUrl?.isNotEmpty ?? false) return NetworkImage(user.photoUrl!);
    return null;
  }
}
