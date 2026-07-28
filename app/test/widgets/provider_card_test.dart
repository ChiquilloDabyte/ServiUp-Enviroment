import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/theme/app_theme.dart';
import 'package:serviup/models/provider_public_profile_model.dart';
import 'package:serviup/widgets/provider_card.dart';

void main() {
  testWidgets('muestra perfil público, categorías y calificación', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const provider = ProviderPublicProfileModel(
      id: 'provider-1',
      name: 'Ana Torres',
      phone: '3001234567',
      serviceCategories: ['Plomería'],
      rating: 4.8,
      ratingCount: 12,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: ProviderCard(provider: provider)),
      ),
    );

    expect(find.text('Ana Torres'), findsOneWidget);
    expect(find.text('Plomería'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Prestador Ana Torres')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
