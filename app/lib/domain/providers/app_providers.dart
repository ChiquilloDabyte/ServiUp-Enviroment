import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/offer_repository.dart';
import '../../data/repositories/offline_repository.dart';
import '../../data/repositories/service_request_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/local_db_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/maps_config_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/places_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/sync_service.dart';
import '../../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
final mapsConfigServiceProvider = Provider<MapsConfigService>(
  (ref) => MapsConfigService(),
);
final placesServiceProvider = Provider<PlacesService>((ref) {
  return GooglePlacesService(
    mapsConfigService: ref.watch(mapsConfigServiceProvider),
  );
});
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);
final localDbServiceProvider = Provider<LocalDbService>(
  (ref) => LocalDbService(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(authServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(firestoreService: ref.watch(firestoreServiceProvider));
});

final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>((
  ref,
) {
  return ServiceRequestRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    serviceRequestRepository: ref.watch(serviceRequestRepositoryProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final offlineRepositoryProvider = Provider<OfflineRepository>((ref) {
  return OfflineRepository(localDbService: ref.watch(localDbServiceProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    firestoreService: ref.watch(firestoreServiceProvider),
    localDbService: ref.watch(localDbServiceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return const Stream.empty();
  return ref.watch(userRepositoryProvider).watchUser(authState.uid);
});

final hasConnectionProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.hasConnection();
  await for (final _ in service.onConnectivityChanged) {
    yield await service.hasConnection();
  }
});
