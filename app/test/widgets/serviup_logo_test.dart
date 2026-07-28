import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/constants/app_constants.dart';
import 'package:serviup/widgets/serviup_logo.dart';

void main() {
  testWidgets('renders the full ServiUp brand lockup', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ServiUpLogo(height: 100))),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(RichText), findsWidgets);

    final semantics = tester.getSemantics(find.byType(ServiUpLogo));
    expect(semantics.label, AppConstants.appName);
  });

  testWidgets('can render the symbol without the wordmark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ServiUpLogo(height: 48, showWordmark: false)),
      ),
    );

    expect(find.byType(ServiUpLogo), findsOneWidget);
    expect(find.textContaining('Servi'), findsNothing);
  });
}
