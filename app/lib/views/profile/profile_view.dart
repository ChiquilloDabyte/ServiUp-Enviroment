import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/auth_viewmodel.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, _) => Center(child: Text(authErrorMessage(error))),
        data:
            (user) =>
                user == null
                    ? const Center(child: Text('Usuario no encontrado'))
                    : _ProfileContent(user: user),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return ResponsiveContent(
      maxWidth: 720,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 52,
                foregroundImage:
                    user.photoUrl?.isNotEmpty ?? false
                        ? NetworkImage(user.photoUrl!)
                        : null,
                child:
                    user.photoUrl?.isNotEmpty ?? false
                        ? null
                        : const Icon(Icons.person_outline, size: 48),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Chip(
                avatar: Icon(
                  user.role == UserRole.client
                      ? Icons.person_outline
                      : Icons.handyman_outlined,
                  size: 18,
                ),
                label: Text(user.role.label),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            child: Column(
              children: [
                _ProfileField(
                  icon: Icons.email_outlined,
                  label: 'Correo',
                  value: user.email,
                ),
                const Divider(height: AppSpacing.md),
                _ProfileField(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: user.phone,
                ),
              ],
            ),
          ),
          if (user.role == UserRole.provider) ...[
            const SizedBox(height: AppSpacing.gutter),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Servicios', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    children:
                        user.serviceCategories
                            .map((category) => Chip(label: Text(category)))
                            .toList(),
                  ),
                  const Divider(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        user.ratingCount == 0
                            ? 'Sin calificaciones'
                            : '${user.rating.toStringAsFixed(1)} '
                                '(${user.ratingCount})',
                        style: textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar perfil'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await ref.read(authViewModelProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(authErrorMessage(error))),
                );
              }
            },
            icon: Icon(Icons.logout, color: colors.error),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}
