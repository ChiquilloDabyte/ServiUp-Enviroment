import 'package:isar/isar.dart';

import '../../models/local_provider_model.dart';
import '../services/local_db_service.dart';

class OfflineRepository {
  OfflineRepository({required LocalDbService localDbService})
      : _localDbService = localDbService;

  final LocalDbService _localDbService;

  Future<List<LocalProvider>> getLocalProviders({String? category}) async {
    final isar = await _localDbService.database;
    final providers = await isar.localProviders.where().findAll();

    if (category == null || category.isEmpty) {
      return providers;
    }

    return providers
        .where((provider) => provider.categories.contains(category))
        .toList();
  }

  Future<DateTime?> getLastSyncTime() async {
    final isar = await _localDbService.database;
    final providers = await isar.localProviders.where().findAll();
    if (providers.isEmpty) return null;
    return providers
        .map((provider) => provider.lastSyncedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }
}
