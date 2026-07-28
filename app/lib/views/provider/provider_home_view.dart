import 'dart:async';

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
  final _searchController = TextEditingController();
  Timer? _debounce;
  double? _lat;
  double? _lng;
  Object? _locationError;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    setState(() => _locationError = null);
    try {
      final location =
          await ref.read(locationServiceProvider).getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _lat = location.latitude;
        _lng = location.longitude;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _locationError = error);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final hasConnection = ref.watch(hasConnectionProvider).value ?? true;

    final AsyncValue<List<ServiceRequestModel>> nearby =
        _lat != null && _lng != null
            ? ref.watch(
              nearbyRequestsProvider((lat: _lat!, lng: _lng!, category: null)),
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
                  _NearbyRequests(
                    requests: nearby,
                    locationError: _locationError,
                    searchQuery: _searchQuery,
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onClearSearch: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    onRetryLocation: _loadLocation,
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

class _NearbyRequests extends StatelessWidget {
  const _NearbyRequests({
    required this.requests,
    required this.locationError,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRetryLocation,
  });

  final AsyncValue<List<ServiceRequestModel>> requests;
  final Object? locationError;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onRetryLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ResponsiveContent(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.mobileMargin,
            AppSpacing.gutter,
            AppSpacing.mobileMargin,
            0,
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por categoría o descripción',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  searchController.text.isEmpty
                      ? null
                      : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.clear),
                      ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child:
              locationError != null
                  ? ResponsiveContent(
                    child: EmptyState(
                      icon: Icons.location_off_outlined,
                      title: 'No pudimos obtener tu ubicación',
                      message:
                          'Activa el permiso de ubicación para buscar '
                          'solicitudes cercanas.',
                      action: FilledButton.icon(
                        onPressed: onRetryLocation,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ),
                  )
                  : requests.when(
                    loading:
                        () => const ResponsiveContent(child: LoadingView()),
                    error:
                        (error, _) => _RequestListError(
                          message: repositoryErrorMessage(error),
                        ),
                    data: (items) {
                      final filtered =
                          items
                              .where(
                                (request) =>
                                    requestMatchesSearch(request, searchQuery),
                              )
                              .toList();
                      return _ProviderRequestList(
                        requests: filtered,
                        emptyTitle: 'No hay solicitudes cercanas',
                        emptyMessage:
                            searchQuery.isEmpty
                                ? 'Las nuevas oportunidades aparecerán aquí.'
                                : 'Prueba con otra categoría o descripción.',
                      );
                    },
                  ),
        ),
      ],
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
