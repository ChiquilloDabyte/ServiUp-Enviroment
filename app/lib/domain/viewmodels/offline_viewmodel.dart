import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/local_provider_model.dart';
import '../providers/app_providers.dart';

final localProvidersProvider =
    FutureProvider.family<List<LocalProvider>, String?>((ref, category) {
  return ref.watch(offlineRepositoryProvider).getLocalProviders(
        category: category,
      );
});

final lastSyncTimeProvider = FutureProvider<DateTime?>((ref) {
  return ref.watch(offlineRepositoryProvider).getLastSyncTime();
});

class OfflineActions {
  OfflineActions(this.ref);

  final Ref ref;

  Future<bool> syncProviders() {
    return ref.read(syncServiceProvider).syncProvidersIfOnline();
  }
}

final offlineActionsProvider = Provider<OfflineActions>((ref) {
  return OfflineActions(ref);
});

/// Keeps provider sync alive for the app lifetime using [Ref], not a widget.
final syncListenerProvider = Provider<void>((ref) {
  final subscription =
      ref.watch(connectivityServiceProvider).onConnectivityChanged.listen(
    (_) async {
      final synced = await ref.read(syncServiceProvider).syncProvidersIfOnline();
      if (!synced) return;
      ref.invalidate(localProvidersProvider);
      ref.invalidate(lastSyncTimeProvider);
    },
  );
  ref.onDispose(subscription.cancel);
});
