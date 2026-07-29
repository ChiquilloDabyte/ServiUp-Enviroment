import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_dimensions.dart';
import '../domain/providers/app_providers.dart';
import '../models/enums/verification_action.dart';
import 'section_card.dart';

Future<void> showAccountRequirementsSheet(
  BuildContext context,
  VerificationAction action,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder:
        (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.mobileMargin),
            child: AccountRequirementsCard(action: action),
          ),
        ),
  );
}

class AccountActionGate extends ConsumerWidget {
  const AccountActionGate({
    super.key,
    required this.action,
    required this.child,
  });

  final VerificationAction action;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verification = ref.watch(accountVerificationProvider);
    if (verification.isReadyFor(action)) return child;
    return AccountRequirementsCard(action: action);
  }
}

class AccountRequirementsCard extends ConsumerWidget {
  const AccountRequirementsCard({super.key, this.action});

  final VerificationAction? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verification = ref.watch(accountVerificationProvider);
    final requirements =
        action == null
            ? verification.accountRequirements
            : verification.requirementsFor(action!);
    if (requirements.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            action == null ? 'Activa tu cuenta' : 'Antes de continuar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Completa solo los pasos necesarios para esta acción.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final requirement in requirements)
            _RequirementTile(requirement: requirement),
        ],
      ),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({required this.requirement});

  final VerificationRequirement requirement;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, route) = switch (requirement) {
      VerificationRequirement.profile => (
        Icons.person_outline,
        'Completar perfil',
        'Agrega la información básica de tu cuenta.',
        '/onboarding',
      ),
      VerificationRequirement.email => (
        Icons.mark_email_unread_outlined,
        'Verificar correo',
        'Confirma el enlace enviado a tu correo.',
        '/verify-email',
      ),
      VerificationRequirement.phone => (
        Icons.phone_android_outlined,
        'Verificar celular',
        'Confirma un número colombiano mediante SMS.',
        '/verify-phone',
      ),
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }
}
