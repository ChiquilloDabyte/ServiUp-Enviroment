import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/app_providers.dart';
import '../../widgets/loading_view.dart';
import 'package:go_router/go_router.dart';
import '../../domain/viewmodels/auth_viewmodel.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);

    return profile.when(
      loading: () => const Scaffold(
        body: LoadingView(),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text(error.toString()),
        ),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('Usuario no encontrado'),
            ),
          );
        }

        debugPrint('PHOTO URL: ${user.photoUrl}');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi Perfil'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? const Icon(Icons.person, size: 55)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.name == 'client'
                        ? 'Cliente'
                        : 'Prestador de servicios',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.email,
                      color: Colors.blue,
                    ),
                    title: const Text('Correo'),
                    subtitle: Text(user.email),
                  ),
                ),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.phone,
                      color: Colors.green,
                    ),
                    title: const Text('Teléfono'),
                    subtitle: Text(user.phone),
                  ),
                ),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 30,
                    ),
                    title: const Text('Calificación'),
                    subtitle: Text(
                      user.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: () {
                    context.push('/profile/edit');
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar perfil'),
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authViewModelProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}