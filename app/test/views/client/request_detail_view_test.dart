import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:serviup/domain/providers/app_providers.dart';
import 'package:serviup/domain/viewmodels/offer_viewmodel.dart';
import 'package:serviup/domain/viewmodels/service_request_viewmodel.dart';
import 'package:serviup/views/client/request_detail_view.dart';

void main() {
  testWidgets('permite volver atrás sin mostrar un botón de inicio', (
    tester,
  ) async {
    const requestId = 'request-1';
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/requests/$requestId'),
                child: const Text('Abrir solicitud'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/requests/:id',
          builder:
              (context, state) => ClientRequestDetailView(
                requestId: state.pathParameters['id']!,
              ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestDetailProvider(
            requestId,
          ).overrideWith((ref) => const Stream.empty()),
          requestOffersProvider(
            requestId,
          ).overrideWith((ref) => const Stream.empty()),
          currentUserProfileProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Abrir solicitud'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byIcon(Icons.home_outlined), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Abrir solicitud'), findsOneWidget);
  });
}
