import 'auth_repository.dart';
import '../services/sync_service.dart';

class ProviderSyncRepository {
  ProviderSyncRepository({
    required AuthRepository authRepository,
    required SyncService syncService,
  }) : _authRepository = authRepository,
       _syncService = syncService;

  final AuthRepository _authRepository;
  final SyncService _syncService;

  Future<bool> syncProvidersIfOnline() {
    return _syncService.syncProvidersIfOnline(
      isSignedIn: _authRepository.currentUser != null,
    );
  }
}
