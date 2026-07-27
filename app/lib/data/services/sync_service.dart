import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/logger/app_logger.dart';
import '../../models/local_provider_model.dart';
import '../../models/provider_public_profile_model.dart';
import 'connectivity_service.dart';
import 'firestore_service.dart';
import 'local_db_service.dart';

class SyncService {
  SyncService({
    required FirestoreService firestoreService,
    required LocalDbService localDbService,
    required ConnectivityService connectivityService,
  }) : _firestoreService = firestoreService,
       _localDbService = localDbService,
       _connectivityService = connectivityService;

  final FirestoreService _firestoreService;
  final LocalDbService _localDbService;
  final ConnectivityService _connectivityService;

  Future<bool> syncProvidersIfOnline({required bool isSignedIn}) async {
    if (!isSignedIn) {
      return false;
    }

    if (!await _connectivityService.hasConnection()) {
      return false;
    }

    try {
      const pageSize = 200;
      final documents = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      Query<Map<String, dynamic>> query = _firestoreService
          .providerPublicProfiles
          .orderBy(FieldPath.documentId)
          .limit(pageSize);
      while (true) {
        final snapshot = await query.get();
        documents.addAll(snapshot.docs);
        if (snapshot.docs.length < pageSize) break;
        query = query.startAfterDocument(snapshot.docs.last);
      }

      final isar = await _localDbService.database;
      final providers =
          documents
              .map(ProviderPublicProfileModel.fromFirestore)
              .where((profile) => profile.phone.isNotEmpty)
              .map(
                (profile) =>
                    LocalProvider()
                      ..firebaseId = profile.id
                      ..name = profile.name
                      ..phone = profile.phone
                      ..categories = profile.serviceCategories
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
