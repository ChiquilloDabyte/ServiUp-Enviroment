import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/provider_public_profile_model.dart';
import '../providers/app_providers.dart';

typedef ProviderSearchFilter = ({String? category, String query});

final providersListProvider = StreamProvider.autoDispose.family<
  List<ProviderPublicProfileModel>,
  ProviderSearchFilter
>((ref, filter) {
  if (!ref.watch(sessionDataEnabledProvider)) return const Stream.empty();
  return ref.watch(userRepositoryProvider).watchProviders().map((providers) {
    return providers
        .where(
          (provider) => providerMatchesSearch(
            provider,
            query: filter.query,
            category: filter.category,
          ),
        )
        .toList();
  });
});

bool providerMatchesSearch(
  ProviderPublicProfileModel provider, {
  required String query,
  String? category,
}) {
  if (category != null &&
      category.isNotEmpty &&
      !provider.serviceCategories.contains(category)) {
    return false;
  }

  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  return provider.name.toLowerCase().contains(normalizedQuery) ||
      provider.serviceCategories.any(
        (providerCategory) =>
            providerCategory.toLowerCase().contains(normalizedQuery),
      );
}
