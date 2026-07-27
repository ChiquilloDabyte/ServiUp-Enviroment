import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_dimensions.dart';
import '../../domain/viewmodels/offline_viewmodel.dart';
import '../../widgets/category_dropdown.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

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
            tooltip: 'Sincronizar directorio',
            icon: const Icon(Icons.sync),
            onPressed: _sync,
          ),
        ],
      ),
      body: Column(
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryDropdown(
                  value: _category,
                  onChanged: (value) => setState(() => _category = value),
                ),
                lastSync.when(
                  data:
                      (date) =>
                          date == null
                              ? const SizedBox.shrink()
                              : Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.sync_outlined,
                                      size: 18,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Última sincronización: $date',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: providers.when(
              loading: () => const ResponsiveContent(child: LoadingView()),
              error:
                  (error, _) => ResponsiveContent(
                    child: EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'No pudimos abrir el directorio',
                      message: error.toString(),
                    ),
                  ),
              data: (items) {
                if (items.isEmpty) {
                  return ResponsiveContent(
                    child: EmptyState(
                      icon: Icons.contacts_outlined,
                      title: 'No hay prestadores guardados',
                      message:
                          'Conéctate a internet y sincroniza para usar '
                          '${AppConstants.appName} sin red.',
                      action: OutlinedButton.icon(
                        onPressed: _sync,
                        icon: const Icon(Icons.sync),
                        label: const Text('Sincronizar'),
                      ),
                    ),
                  );
                }

                return ResponsiveContent(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder:
                        (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final provider = items[index];
                      return SectionCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryFixed,
                              foregroundColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryFixedVariant,
                              child: Text(
                                provider.name.isEmpty
                                    ? '?'
                                    : provider.name.characters.first
                                        .toUpperCase(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.gutter),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    provider.categories.join(', '),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              tooltip: 'Llamar a ${provider.name}',
                              icon: const Icon(Icons.phone_outlined),
                              onPressed: () => _call(provider.phone),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
