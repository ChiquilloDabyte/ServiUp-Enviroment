import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/widgets/main_navigation_shell.dart';

void main() {
  testWidgets('muestra los destinos principales y permite seleccionarlos', (
    tester,
  ) async {
    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationShell(
          currentIndex: 0,
          onDestinationSelected: (index) => selectedIndex = index,
          child: const Center(child: Text('Contenido')),
        ),
      ),
    );

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Conversaciones'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Contenido'), findsOneWidget);

    await tester.tap(find.text('Conversaciones'));

    expect(selectedIndex, 1);
  });
}
