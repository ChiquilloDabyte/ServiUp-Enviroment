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
      final location =
          await ref.read(locationServiceProvider).getCurrentLocation();
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

    final AsyncValue<List<ServiceRequestModel>> nearby =
        _lat != null && _lng != null
            ? ref.watch(
              nearbyRequestsProvider((
                lat: _lat!,
                lng: _lng!,
                category: _categoryFilter,
              )),
            )
            : const AsyncValue<List<ServiceRequestModel>>.loading();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel prestador'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Cercanas'), Tab(text: 'Mis trabajos')],
          ),
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
                message: 'Sin conexión. Consulta el directorio offline.',
                onViewDirectory: () => context.push('/offline'),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  nearby.when(
                    loading:
                        () => const ResponsiveContent(child: LoadingView()),
                    error:
                        (error, _) => _RequestListError(
                          message: repositoryErrorMessage(error),
                        ),
                    data:
                        (requests) => _ProviderRequestList(
                          requests: requests,
                          emptyTitle: 'No hay solicitudes cercanas',
                          emptyMessage:
                              'Las nuevas oportunidades aparecerán aquí.',
                        ),
                  ),
                  user == null
                      ? const ResponsiveContent(child: LoadingView())
                      : ref
                          .watch(providerActiveJobsProvider(user.id))
                          .when(
                            loading:
                                () => const ResponsiveContent(
                                  child: LoadingView(),
                                ),
                            error:
                                (error, _) => _RequestListError(
                                  message: repositoryErrorMessage(error),
                                ),
                            data:
                                (jobs) => _ProviderRequestList(
                                  requests: jobs,
                                  emptyTitle: 'No tienes trabajos activos',
                                  emptyMessage:
                                      'Los servicios aceptados aparecerán aquí.',
                                ),
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

class _ProviderRequestList extends StatelessWidget {
  const _ProviderRequestList({
    required this.requests,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final List<ServiceRequestModel> requests;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return ResponsiveContent(
        child: EmptyState(
          icon: Icons.search_off_outlined,
          title: emptyTitle,
          message: emptyMessage,
        ),
      );
    }

    return ResponsiveContent(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.gutter),
        itemBuilder: (context, index) {
          final request = requests[index];
          return RequestCard(
            request: request,
            onTap: () => context.push('/provider/requests/${request.id}'),
          );
        },
      ),
    );
  }
}

class _RequestListError extends StatelessWidget {
  const _RequestListError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContent(
      child: EmptyState(
        icon: Icons.error_outline,
        title: 'No pudimos cargar las solicitudes',
        message: message,
      ),
    );
  }
}
