import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/theme/app_theme.dart';
import 'package:serviup/views/auth/forgot_password_view.dart';
import 'package:serviup/views/auth/login_view.dart';
import 'package:serviup/views/auth/register_view.dart';
import 'package:serviup/widgets/responsive_content.dart';
import 'package:serviup/widgets/section_card.dart';

void main() {
  Widget buildSubject(Widget child) {
    return ProviderScope(
      child: MaterialApp(theme: AppTheme.lightTheme, home: child),
    );
  }

  testWidgets('login uses the shared responsive form surface', (tester) async {
    await tester.pumpWidget(buildSubject(const LoginView()));

    expect(find.byType(ResponsiveContent), findsOneWidget);
    expect(find.byType(SectionCard), findsOneWidget);
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ingresar'), findsOneWidget);
  });

  testWidgets('login keeps field validation behavior', (tester) async {
    await tester.pumpWidget(buildSubject(const LoginView()));

    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pump();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
  });

  testWidgets('register exposes roles and legal acceptance', (tester) async {
    await tester.pumpWidget(buildSubject(const RegisterView()));

    expect(find.byType(ResponsiveContent), findsOneWidget);
    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('Prestador'), findsOneWidget);
    expect(find.text('Términos y Condiciones'), findsOneWidget);
    expect(find.text('Política de Privacidad'), findsOneWidget);
  });

  testWidgets('forgot password uses the shared responsive form surface', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(const ForgotPasswordView()));

    expect(find.byType(ResponsiveContent), findsOneWidget);
    expect(find.byType(SectionCard), findsOneWidget);
    expect(find.text('Recupera tu acceso'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Enviar enlace'), findsOneWidget);
  });
}
