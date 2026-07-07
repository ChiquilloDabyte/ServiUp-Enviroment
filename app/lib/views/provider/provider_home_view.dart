import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/auth_viewmodel.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/request_card.dart';

class ProviderHomeView extends ConsumerStatefulWidget {
  const ProviderHomeView({super.key});

  @override
  ConsumerState<ProviderHomeView> createState() => _ProviderHomeViewState();
}

class _ProviderHomeViewState extends ConsumerState<ProviderHomeView> {
  String? _categoryFilter;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final location = await ref.read(locationServiceProvider).getCurrentLocation();
      setState(() {
        _lat = location.latitude;
        _lng = location.longitude;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final hasConnection = ref.watch(hasConnectionProvider).value ?? true;

    final nearby = _lat != null && _lng != null
        ? ref.watch(nearbyRequestsProvider((lat: _lat!, lng: _lng!, category: _categoryFilter)))
        : const AsyncValue<List<dynamic>>.loading();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel prestador'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Cercanas'),
              Tab(text: 'Mis trabajos'),
            ],
          ),
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
                content: const Text('Sin conexión. Consulta el directorio offline.'),
                actions: [
                  TextButton(
                    onPressed: () => context.push('/offline'),
                    child: const Text('Ver directorio'),
                  ),
                ],
              ),
            Expanded(
              child: TabBarView(
                children: [
                  nearby.when(
                    loading: () => const LoadingView(),
                    error: (error, _) => Center(child: Text(repositoryErrorMessage(error))),
                    data: (requests) {
                      if (requests.isEmpty) {
                        return const Center(child: Text('No hay solicitudes cercanas.'));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return RequestCard(
                            request: request,
                            onTap: () => context.push('/provider/requests/${request.id}'),
                          );
                        },
                      );
                    },
                  ),
                  user == null
                      ? const LoadingView()
                      : ref.watch(providerActiveJobsProvider(user.id)).when(
                            loading: () => const LoadingView(),
                            error: (error, _) =>
                                Center(child: Text(repositoryErrorMessage(error))),
                            data: (jobs) {
                              if (jobs.isEmpty) {
                                return const Center(child: Text('No tienes trabajos activos.'));
                              }

                              return ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: jobs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final job = jobs[index];
                                  return RequestCard(
                                    request: job,
                                    onTap: () =>
                                        context.push('/provider/requests/${job.id}'),
                                  );
                                },
                              );
                            },
                          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
