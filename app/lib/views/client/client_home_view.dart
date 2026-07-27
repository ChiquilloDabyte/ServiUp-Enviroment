import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/auth_viewmodel.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../models/service_request_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/request_card.dart';
import '../../widgets/responsive_content.dart';

class ClientHomeView extends ConsumerWidget {
  const ClientHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final AsyncValue<List<ServiceRequestModel>> requests =
        user == null
            ? const AsyncValue<List<ServiceRequestModel>>.loading()
            : ref.watch(clientRequestsProvider(user.id));
    final hasConnection = ref.watch(hasConnectionProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        actions: [
          IconButton(
            tooltip: 'Conversaciones',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/chats'),
          ),
          IconButton(
            tooltip: 'Notificaciones',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!hasConnection)
            OfflineBanner(
              message: 'Sin conexión. Puedes ver prestadores offline.',
              onViewDirectory: () => context.push('/offline'),
            ),
          Expanded(
            child: requests.when(
              loading: () => const ResponsiveContent(child: LoadingView()),
              error:
                  (error, _) => ResponsiveContent(
                    child: EmptyState(
                      icon: Icons.error_outline,
                      title: 'No pudimos cargar tus solicitudes',
                      message: repositoryErrorMessage(error),
                    ),
                  ),
              data: (items) {
                if (items.isEmpty) {
                  return ResponsiveContent(
                    child: EmptyState(
                      icon: Icons.handyman_outlined,
                      title: 'Aún no tienes solicitudes',
                      message: 'Publica la primera y encuentra ayuda cerca.',
                      action: FilledButton.icon(
                        onPressed: () => context.push('/requests/create'),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva solicitud'),
                      ),
                    ),
                  );
                }

                return ResponsiveContent(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder:
                        (_, __) => const SizedBox(height: AppSpacing.gutter),
                    itemBuilder: (context, index) {
                      final request = items[index];
                      return RequestCard(
                        request: request,
                        onTap: () => context.push('/requests/${request.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/requests/create'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva solicitud'),
      ),
    );
  }
}
