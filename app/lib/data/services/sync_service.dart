import '../../core/logger/app_logger.dart';
import '../../models/enums/user_role.dart';
import '../../models/local_provider_model.dart';
import '../../models/user_model.dart';
import 'connectivity_service.dart';
import 'firestore_service.dart';
import 'local_db_service.dart';

class SyncService {
  SyncService({
    required FirestoreService firestoreService,
    required LocalDbService localDbService,
    required ConnectivityService connectivityService,
  })  : _firestoreService = firestoreService,
        _localDbService = localDbService,
        _connectivityService = connectivityService;

  final FirestoreService _firestoreService;
  final LocalDbService _localDbService;
  final ConnectivityService _connectivityService;

  Future<void> startListening(void Function() onSynced) async {
    _connectivityService.onConnectivityChanged.listen((_) async {
      final synced = await syncProvidersIfOnline();
      if (synced) onSynced();
    });
  }

  Future<bool> syncProvidersIfOnline() async {
    if (!await _connectivityService.hasConnection()) {
      return false;
    }

    try {
      final snapshot = await _firestoreService.users
          .where('role', isEqualTo: UserRole.provider.value)
          .where('profileComplete', isEqualTo: true)
          .get();

      final isar = await _localDbService.database;
      final providers = snapshot.docs
          .map(UserModel.fromFirestore)
          .where((user) => user.phone.isNotEmpty)
          .map(
            (user) => LocalProvider()
              ..firebaseId = user.id
              ..name = user.name
              ..phone = user.phone
              ..categories = user.serviceCategories
              ..lastSyncedAt = DateTime.now(),
          )
          .toList();

      await isar.writeTxn(() async {
        await isar.localProviders.clear();
        await isar.localProviders.putAll(providers);
      });

      AppLogger.info('Synced ${providers.length} local providers');
      return true;
    } catch (e, stack) {
      AppLogger.error('Provider sync failed', e, stack);
      return false;
    }
  }
}
