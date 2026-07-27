import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/connectivity_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/offer_repository.dart';
import '../../data/repositories/offline_repository.dart';
import '../../data/repositories/provider_sync_repository.dart';
import '../../data/repositories/service_request_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/cloud_functions_service.dart';
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
final _locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(
    locationService: ref.watch(_locationServiceProvider),
  );
});
final Provider<LocationRepository> locationServiceProvider =
    locationRepositoryProvider;
final mapsConfigServiceProvider = Provider<MapsConfigService>(
  (ref) => MapsConfigService(),
);
final placesServiceProvider = Provider<PlacesService>((ref) {
  return GooglePlacesService(
    mapsConfigService: ref.watch(mapsConfigServiceProvider),
  );
});
final _connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);
final connectivityRepositoryProvider = Provider<ConnectivityRepository>((ref) {
  return ConnectivityRepository(
    connectivityService: ref.watch(_connectivityServiceProvider),
  );
});
final Provider<ConnectivityRepository> connectivityServiceProvider =
    connectivityRepositoryProvider;
final localDbServiceProvider = Provider<LocalDbService>(
  (ref) => LocalDbService(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);
final cloudFunctionsServiceProvider = Provider<CloudFunctionsService>(
  (ref) => CloudFunctionsService(),
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
    cloudFunctionsService: ref.watch(cloudFunctionsServiceProvider),
    locationRepository: ref.watch(locationRepositoryProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    cloudFunctionsService: ref.watch(cloudFunctionsServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    cloudFunctionsService: ref.watch(cloudFunctionsServiceProvider),
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

final _syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    firestoreService: ref.watch(firestoreServiceProvider),
    localDbService: ref.watch(localDbServiceProvider),
    connectivityService: ref.watch(_connectivityServiceProvider),
  );
});
final providerSyncRepositoryProvider = Provider<ProviderSyncRepository>((ref) {
  return ProviderSyncRepository(
    authRepository: ref.watch(authRepositoryProvider),
    syncService: ref.watch(_syncServiceProvider),
  );
});
final Provider<ProviderSyncRepository> syncServiceProvider =
    providerSyncRepositoryProvider;

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return const Stream.empty();
  return ref.watch(userRepositoryProvider).watchUser(authState.uid);
});

final fcmTokenRefreshProvider = Provider<void>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final subscription = repository.onFcmTokenRefresh.listen(
    repository.syncFcmToken,
  );
  ref.onDispose(subscription.cancel);
});

final hasConnectionProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityRepositoryProvider);
  yield await service.hasConnection();
  await for (final _ in service.onConnectivityChanged) {
    yield await service.hasConnection();
  }
});
