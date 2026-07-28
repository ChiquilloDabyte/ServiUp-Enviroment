import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:serviup/domain/viewmodels/auth_viewmodel.dart';
import 'package:serviup/domain/viewmodels/provider_viewmodel.dart';
import 'package:serviup/models/enums/user_role.dart';
import 'package:serviup/widgets/provider_card.dart';

import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/auth_viewmodel.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/request_card.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../models/user_model.dart';

//This will be a statefullwidget. To let open the chance to make the cards open, -
// for example to show a highe description of the provider

class dashboardView extends ConsumerStatefulWidget { // It says that a[StatefulWidget] can read providers. {}
  const dashboardView({super.key});

  @override
  ConsumerState<dashboardView> createState() => _dashboardViewState();
}

class _dashboardViewState extends ConsumerState<dashboardView> {
  String? _categoryFilter;
  double? _lat;
  double? _lng;

  // 1. Controller para leer/limpiar el texto del buscador
  final _searchController = TextEditingController();

  // 2. Debounce timer: evita disparar una búsqueda en cada tecla presionada
  Timer? _debounce;

  // 3. Query "confirmado" que realmente se usa para filtrar/pedir datos
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }


  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = value.trim());
      // TODO: if the results are bigger than hundred, it's convenient to change this to search
      // the results from back and not from front(here). So, pass the _searchQuery to provider.
    });
  }

  /* This is usefull if I need to load a previous data, and that's true
  TODO: look if always that I load data I need a statefull */
  @override
  void initState() {
    super.initState();
  }
  
  

  // This will be the function to load the data that I validate in initState above
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
    final hasConnection = ref.watch(hasConnectionProvider).value ?? true;
    final user = ref.watch(currentUserProfileProvider).value;
    final isProvider = user?.role == UserRole.provider;

    final providers = !isProvider
        ? ref.watch(providersListProvider(_categoryFilter))
        : null;

    // The code below should be completed to load also for any location (at least, for further services locations)
    if (isProvider && _lat == null && _lng == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocation());
    }

    final nearbyRequests = isProvider && _lat != null && _lng != null
        ? ref.watch(nearbyRequestsProvider((lat: _lat!, lng: _lng!, category: _categoryFilter)))
        : null;

    // Put the return with a component like scaffold and appbar and more
    return Scaffold(
      appBar: AppBar(
        title: Text(isProvider ? 'Buscar servicio' : 'Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications')
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsetsGeometry.fromLTRB(16,0,12,16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: isProvider ? 'Buscar servicio...' : 'Buscar categoría de provider...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                prefixIcon: const Icon(Icons.search),
                // 5. Button to clean, only visible if there are text
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

              ),
            ),
          )
        ),
      ),
      // Here I should add the search section with the same scaffold color. So TODO: add the another green section for the search option
      body: Column( // Here I can use the another provider_home_view
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
              child: SafeArea(
                child: SingleChildScrollView(
                  child: isProvider
                      ? _buildRequestsList(nearbyRequests)
                      : _buildProvidersList(providers),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildRequestsList(AsyncValue? nearbyRequests) {
    if (nearbyRequests == null) return const LoadingView();

    return nearbyRequests.when(
      loading: () => const LoadingView(),
      error: (error, _) => Center(child: Text(repositoryErrorMessage(error))),
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(child: Text('No hay solicitudes cercanas.'));
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
    );
  }

  Widget _buildProvidersList(AsyncValue<List<UserModel>>? providers) {
  if (providers == null) return const LoadingView();

  return providers.when(
    loading: () => const LoadingView(),
    error: (error, _) => Center(child: Text(repositoryErrorMessage(error))),
    data: (list) {
      if (list.isEmpty) {
        return const Center(child: Text('No hay proveedores disponibles.'));
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final provider = list[index];
          return ProviderCard(
            provider: provider,
            onTap: () => context.push('/client/providers/${provider.id}'),
          );
        },
      );
    },
  );
  }
}