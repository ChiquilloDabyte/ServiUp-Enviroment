import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../providers/app_providers.dart';

/// Providers activos (role = provider, profileComplete = true),
/// opcionalmente filtrados por categoría de servicio.
final providersListProvider = StreamProvider.autoDispose
    .family<List<UserModel>, String?>((ref, category) {
  final stream = ref.watch(userRepositoryProvider).watchProviders();

  if (category == null || category.isEmpty) return stream;

  return stream.map(
    (providers) => providers
        .where((p) => p.serviceCategories.contains(category))
        .toList(),
  );
});