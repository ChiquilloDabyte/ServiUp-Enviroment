import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/errors/app_exception.dart';
import 'package:serviup/domain/viewmodels/review_viewmodel.dart';
import 'package:serviup/models/enums/request_status.dart';
import 'package:serviup/models/service_request_model.dart';

void main() {
  test('rechaza calificaciones para servicios no completados', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final request = ServiceRequestModel(
      id: 'request-1',
      clientId: 'client-1',
      category: 'Plomería',
      description: 'Reparar una fuga',
      latitude: 4.7,
      longitude: -74.1,
      address: 'Calle 1',
      scheduledAt: DateTime(2026, 7, 30),
      status: RequestStatus.inProgress,
      acceptedProviderId: 'provider-1',
    );

    await expectLater(
      container
          .read(reviewViewModelProvider.notifier)
          .createReview(
            request: request,
            clientId: 'client-1',
            rating: 5,
            comment: '',
          ),
      throwsA(isA<RepositoryException>()),
    );
  });
}
