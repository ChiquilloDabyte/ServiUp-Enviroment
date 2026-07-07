import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/viewmodels/offline_viewmodel.dart';
import '../../widgets/category_dropdown.dart';
import '../../widgets/loading_view.dart';

class OfflineProvidersView extends ConsumerStatefulWidget {
  const OfflineProvidersView({super.key});

  @override
  ConsumerState<OfflineProvidersView> createState() =>
      _OfflineProvidersViewState();
}

class _OfflineProvidersViewState extends ConsumerState<OfflineProvidersView> {
  String? _category;

  Future<void> _sync() async {
    final synced = await ref.read(offlineActionsProvider).syncProviders();
    ref.invalidate(localProvidersProvider);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? 'Directorio actualizado.'
              : 'No hay conexión para sincronizar.',
        ),
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(localProvidersProvider(_category));
    final lastSync = ref.watch(lastSyncTimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio offline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _sync,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CategoryDropdown(
              value: _category,
              onChanged: (value) => setState(() => _category = value),
            ),
          ),
          lastSync.when(
            data: (date) => date == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Última sincronización: $date'),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: providers.when(
              loading: () => const LoadingView(),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No hay prestadores guardados. Conéctate a internet y sincroniza para usar ${AppConstants.appName} sin red.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final provider = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(provider.name),
                        subtitle: Text(provider.categories.join(', ')),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: () => _call(provider.phone),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
