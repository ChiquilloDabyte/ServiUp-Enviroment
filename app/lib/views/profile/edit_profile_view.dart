import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/app_providers.dart';
import '../../models/user_model.dart';


class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loaded = false;
  bool _saving = false;

  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
    });
  }

  Future<void> _saveProfile(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      String? photoUrl = user.photoUrl;

      if (_selectedImage != null) {
        photoUrl = await ref
            .read(authRepositoryProvider)
            .uploadAvatar(_selectedImage!);
      }

      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: photoUrl,
      );

      await ref.read(userRepositoryProvider).saveProfile(updatedUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    if (mounted) {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);

    return profile.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text(e.toString())),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Usuario no encontrado')),
          );
        }

        if (!_loaded) {
          _loaded = true;
          _nameController.text = user.name;
          _phoneController.text = user.phone;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Editar perfil"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [

                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage:
                          _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (user.photoUrl != null
                                  ? NetworkImage(user.photoUrl!)
                                  : null) as ImageProvider?,
                      child: _selectedImage == null && user.photoUrl == null
                          ? const Icon(Icons.person, size: 45)
                          : null,
                    ),
                  ),

                  const SizedBox(height:20),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Nombre",
                    ),
                  ),

                  const SizedBox(height:20),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: "Teléfono",
                    ),
                  ),

                  const SizedBox(height:30),

                  FilledButton(
                    onPressed: _saving ? null : () => _saveProfile(user),
                    child: Text(
                      _saving ? "Guardando..." : "Guardar cambios",
                    ),
                  )

                ],
              ),
            ),
          ),
        );
      },
    );
  }
}