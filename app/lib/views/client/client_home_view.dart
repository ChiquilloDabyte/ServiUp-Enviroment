import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/auth_viewmodel.dart';
import '../../domain/viewmodels/provider_viewmodel.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../models/provider_public_profile_model.dart';
import '../../models/service_request_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/account_requirements_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/provider_card.dart';
import '../../widgets/request_card.dart';
import '../../widgets/responsive_content.dart';

class ClientHomeView extends ConsumerStatefulWidget {
  const ClientHomeView({super.key});

  @override
  ConsumerState<ClientHomeView> createState() => _ClientHomeViewState();
}

class _ClientHomeViewState extends ConsumerState<ClientHomeView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
    final AsyncValue<List<ServiceRequestModel>> requests =
        user == null
            ? const AsyncValue<List<ServiceRequestModel>>.loading()
            : ref.watch(clientRequestsProvider(user.id));
    final providers = ref.watch(
      providersListProvider((category: null, query: _searchQuery)),
    );
    final hasConnection = ref.watch(hasConnectionProvider).value ?? true;
    final verification = ref.watch(accountVerificationProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel cliente'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Prestadores'), Tab(text: 'Mis solicitudes')],
          ),
          actions: [
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
            if (verification.accountRequirements.isNotEmpty)
              const ResponsiveContent(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.mobileMargin,
                  AppSpacing.gutter,
                  AppSpacing.mobileMargin,
                  0,
                ),
                child: AccountRequirementsCard(),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _ProviderDirectory(
                    providers: providers,
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onClearSearch: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
                  _ClientRequests(requests: requests),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/requests/create'),
          icon: const Icon(Icons.add),
          label: const Text('Nueva solicitud'),
        ),
      ),
    );
  }
}

class _ProviderDirectory extends StatelessWidget {
  const _ProviderDirectory({
    required this.providers,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final AsyncValue<List<ProviderPublicProfileModel>> providers;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

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
              hintText: 'Buscar por nombre o categoría',
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
          child: providers.when(
            loading: () => const ResponsiveContent(child: LoadingView()),
            error:
                (error, _) => ResponsiveContent(
                  child: EmptyState(
                    icon: Icons.error_outline,
                    title: 'No pudimos cargar los prestadores',
                    message: repositoryErrorMessage(error),
                  ),
                ),
            data: (items) {
              if (items.isEmpty) {
                return const ResponsiveContent(
                  child: EmptyState(
                    icon: Icons.person_search_outlined,
                    title: 'No encontramos prestadores',
                    message: 'Prueba con otro nombre o categoría de servicio.',
                  ),
                );
              }

              return ResponsiveContent(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder:
                      (_, __) => const SizedBox(height: AppSpacing.gutter),
                  itemBuilder:
                      (context, index) => ProviderCard(provider: items[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ClientRequests extends StatelessWidget {
  const _ClientRequests({required this.requests});

  final AsyncValue<List<ServiceRequestModel>> requests;

  @override
  Widget build(BuildContext context) {
    return requests.when(
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
    );
  }
}
