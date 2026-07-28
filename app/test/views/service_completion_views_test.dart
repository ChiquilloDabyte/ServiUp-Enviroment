import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/domain/providers/app_providers.dart';
import 'package:serviup/domain/viewmodels/offer_viewmodel.dart';
import 'package:serviup/domain/viewmodels/review_viewmodel.dart';
import 'package:serviup/domain/viewmodels/service_request_viewmodel.dart';
import 'package:serviup/models/enums/request_status.dart';
import 'package:serviup/models/enums/user_role.dart';
import 'package:serviup/models/service_request_model.dart';
import 'package:serviup/models/user_model.dart';
import 'package:serviup/views/client/request_detail_view.dart';
import 'package:serviup/views/provider/provider_request_detail_view.dart';

void main() {
  const requestId = 'request-completion';
  final scheduledAt = DateTime(2026, 7, 30, 10);

  ServiceRequestModel request(RequestStatus status) {
    return ServiceRequestModel(
      id: requestId,
      clientId: 'client-1',
      category: 'Plomería',
      description: 'Reparar una fuga en la cocina',
      latitude: 4.71,
      longitude: -74.07,
      address: 'Dirección de prueba',
      scheduledAt: scheduledAt,
      status: status,
      acceptedProviderId: 'provider-1',
    );
  }

  testWidgets('el cliente puede confirmar o devolver el servicio', (
    tester,
  ) async {
    const client = UserModel(
      id: 'client-1',
      email: 'client@example.com',
      role: UserRole.client,
      name: 'Cliente',
      phone: '3000000000',
    );
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestDetailProvider(requestId).overrideWith(
            (ref) => Stream.value(request(RequestStatus.pendingConfirmation)),
          ),
          requestOffersProvider(
            requestId,
          ).overrideWith((ref) => Stream.value(const [])),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(client),
          ),
        ],
        child: const MaterialApp(
          home: ClientRequestDetailView(requestId: requestId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confirmar finalización'), findsOneWidget);
    expect(find.text('Todavía falta trabajo'), findsOneWidget);
    await tester.tap(find.text('Todavía falta trabajo'));
    await tester.pumpAndSettle();
    expect(find.text('Devolver al prestador'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('el prestador solicita confirmación sin completar directamente', (
    tester,
  ) async {
    const provider = UserModel(
      id: 'provider-1',
      email: 'provider@example.com',
      role: UserRole.provider,
      name: 'Prestador',
      phone: '3111111111',
    );
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerRequestDetailProvider(requestId).overrideWith(
            (ref) => Stream.value(request(RequestStatus.inProgress)),
          ),
          providerOffersProvider(
            provider.id,
          ).overrideWith((ref) => Stream.value(const [])),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(provider),
          ),
        ],
        child: const MaterialApp(
          home: ProviderRequestDetailView(requestId: requestId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Solicitar confirmación'), findsOneWidget);
    expect(find.text('Marcar como completado'), findsNothing);
  });

  testWidgets(
    'el cliente puede calificar un servicio completado una sola vez',
    (tester) async {
      const client = UserModel(
        id: 'client-1',
        email: 'client@example.com',
        role: UserRole.client,
        name: 'Cliente',
        phone: '3000000000',
      );
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            requestDetailProvider(requestId).overrideWith(
              (ref) => Stream.value(request(RequestStatus.completed)),
            ),
            requestOffersProvider(
              requestId,
            ).overrideWith((ref) => Stream.value(const [])),
            reviewDetailProvider(
              requestId,
            ).overrideWith((ref) => Stream.value(null)),
            currentUserProfileProvider.overrideWith(
              (ref) => Stream.value(client),
            ),
          ],
          child: const MaterialApp(
            home: ClientRequestDetailView(requestId: requestId),
          ),
        ),
      );
      await tester.pumpAndSettle();

    expect(find.text('Calificar servicio'), findsOneWidget);
    },
  );
}
