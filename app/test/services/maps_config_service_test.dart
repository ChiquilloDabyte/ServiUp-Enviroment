import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/errors/app_exception.dart';
import 'package:serviup/data/services/maps_config_service.dart';

void main() {
  test('getApiKey loads and caches platform key', () async {
    var calls = 0;
    final service = MapsConfigService(
      apiKeyLookup: () async {
        calls++;
        return 'test-api-key';
      },
    );

    expect(await service.getApiKey(), 'test-api-key');
    expect(await service.getApiKey(), 'test-api-key');
    expect(calls, 1);
  });

  test('getApiKey rejects missing platform configuration', () async {
    final service = MapsConfigService(apiKeyLookup: () async => null);

    expect(service.getApiKey(), throwsA(isA<RepositoryException>()));
  });
}
