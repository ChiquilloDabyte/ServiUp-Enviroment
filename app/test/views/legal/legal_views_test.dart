import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/theme/app_theme.dart';
import 'package:serviup/views/legal/privacy_policy_view.dart';
import 'package:serviup/views/legal/terms_conditions_view.dart';
import 'package:serviup/widgets/responsive_content.dart';
import 'package:serviup/widgets/section_card.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(theme: AppTheme.lightTheme, home: child);
  }

  testWidgets('terms are presented in the responsive reading surface', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(const TermsConditionsView()));
    await tester.pumpAndSettle();

    expect(find.byType(ResponsiveContent), findsOneWidget);
    expect(find.byType(SectionCard), findsOneWidget);
    expect(find.text('Última actualización: Julio de 2026'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('privacy policy is presented in the responsive reading surface', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(const PrivacyPolicyView()));
    await tester.pumpAndSettle();

    expect(find.byType(ResponsiveContent), findsOneWidget);
    expect(find.byType(SectionCard), findsOneWidget);
    expect(find.text('Última actualización: Julio de 2026'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
  });
}
