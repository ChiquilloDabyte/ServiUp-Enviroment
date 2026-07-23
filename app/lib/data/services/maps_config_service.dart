import 'package:flutter/services.dart';

import '../../core/errors/app_exception.dart';
import '../../core/logger/app_logger.dart';

typedef MapsApiKeyLookup = Future<String?> Function();

class MapsConfigService {
  MapsConfigService({MapsApiKeyLookup? apiKeyLookup})
    : _apiKeyLookup = apiKeyLookup ?? _lookupPlatformApiKey;

  static const _channel = MethodChannel('serviup/maps_config');
  static const _environmentApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  final MapsApiKeyLookup _apiKeyLookup;
  Future<String>? _apiKeyFuture;

  Future<String> getApiKey() {
    return _apiKeyFuture ??= _loadApiKey();
  }

  Future<String> _loadApiKey() async {
    if (_environmentApiKey.isNotEmpty) return _environmentApiKey;

    try {
      final apiKey = (await _apiKeyLookup())?.trim();
      if (apiKey == null || apiKey.isEmpty || apiKey.startsWith(r'$(')) {
        throw const RepositoryException(
          'La búsqueda de direcciones no está configurada.',
        );
      }
      return apiKey;
    } catch (error, stackTrace) {
      if (error is RepositoryException) rethrow;
      AppLogger.error('Failed to load Google Maps API key', error, stackTrace);
      throw const RepositoryException(
        'La búsqueda de direcciones no está disponible.',
      );
    }
  }

  static Future<String?> _lookupPlatformApiKey() {
    return _channel.invokeMethod<String>('getApiKey');
  }
}
