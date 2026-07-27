import 'package:connectivity_plus/connectivity_plus.dart';

import '../services/connectivity_service.dart';

class ConnectivityRepository {
  ConnectivityRepository({required ConnectivityService connectivityService})
    : _connectivityService = connectivityService;

  final ConnectivityService _connectivityService;

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivityService.onConnectivityChanged;

  Future<bool> hasConnection() => _connectivityService.hasConnection();
}
