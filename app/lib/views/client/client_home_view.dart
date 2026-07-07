import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/auth_viewmodel.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/request_card.dart';

class ClientHomeView extends ConsumerWidget {
  const ClientHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final requests = user == null
        ? const AsyncValue<List<dynamic>>.loading()
        : ref.watch(clientRequestsProvider(user.id));
    final hasConnection = ref.watch(hasConnectionProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
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
            MaterialBanner(
              content: const Text('Sin conexión. Puedes ver prestadores offline.'),
              actions: [
                TextButton(
                  onPressed: () => context.push('/offline'),
                  child: const Text('Ver directorio'),
                ),
              ],
            ),
          Expanded(
            child: requests.when(
              loading: () => const LoadingView(),
              error: (error, _) => Center(
                child: Text(repositoryErrorMessage(error)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Aún no tienes solicitudes. Crea la primera.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = items[index];
                    return RequestCard(
                      request: request,
                      onTap: () => context.push('/requests/${request.id}'),
                    );
                  },
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
