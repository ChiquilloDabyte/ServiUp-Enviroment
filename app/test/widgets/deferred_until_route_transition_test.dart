import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/widgets/deferred_until_route_transition.dart';

void main() {
  testWidgets('monta el contenido después de terminar la transición', (
    tester,
  ) async {
    final transition = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 400),
    );
    addTearDown(transition.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeferredUntilRouteTransition(
            transitionAnimation: transition,
            placeholder: const Text('Esperando'),
            builder: (_) => const Text('Mapa listo'),
          ),
        ),
      ),
    );

    expect(find.text('Esperando'), findsOneWidget);
    expect(find.text('Mapa listo'), findsNothing);

    transition.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Esperando'), findsOneWidget);
    expect(find.text('Mapa listo'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Mapa listo'), findsOneWidget);
  });
}
