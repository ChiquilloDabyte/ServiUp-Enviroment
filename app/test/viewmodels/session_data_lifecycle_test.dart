import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/domain/providers/app_providers.dart';
import 'package:serviup/domain/viewmodels/service_request_viewmodel.dart';

void main() {
  test(
    'no recrea consultas de solicitudes mientras cierra la sesión',
    () async {
      var repositoryWasRead = false;
      final container = ProviderContainer(
        overrides: [
          serviceRequestRepositoryProvider.overrideWith((ref) {
            repositoryWasRead = true;
            throw StateError('No debe abrir una consulta autenticada');
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(sessionDataEnabledProvider.notifier).state = false;

      final nearby = await container.read(
        nearbyRequestsProvider((lat: 4.6, lng: -74.1, category: null)).future,
      );
      final activeJobs = container.listen(
        providerActiveJobsProvider('provider-1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(activeJobs.close);
      await Future<void>.delayed(Duration.zero);

      expect(nearby, isEmpty);
      expect(repositoryWasRead, isFalse);
    },
  );
}
