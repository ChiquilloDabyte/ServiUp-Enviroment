import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/domain/providers/app_providers.dart';
import 'package:serviup/models/account_verification_state.dart';
import 'package:serviup/models/enums/user_role.dart';
import 'package:serviup/models/enums/verification_action.dart';
import 'package:serviup/models/user_model.dart';
import 'package:serviup/views/auth/phone_verification_view.dart';
import 'package:serviup/widgets/account_requirements_card.dart';

void main() {
  testWidgets('publicar solicita perfil y correo, pero no teléfono', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountVerificationProvider.overrideWithValue(
            const AccountVerificationState(
              role: UserRole.client,
              profileComplete: false,
              emailVerified: false,
              phoneVerified: false,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AccountRequirementsCard(
              action: VerificationAction.publishRequest,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Completar perfil'), findsOneWidget);
    expect(find.text('Verificar correo'), findsOneWidget);
    expect(find.text('Verificar celular'), findsNothing);
  });

  testWidgets('prestador ve entrada colombiana y aviso de privacidad', (
    tester,
  ) async {
    const provider = UserModel(
      id: 'provider-1',
      email: 'provider@example.com',
      role: UserRole.provider,
      name: 'Prestador',
      phone: '',
      profileComplete: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(provider),
          ),
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        ],
        child: const MaterialApp(home: PhoneVerificationView()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Confirma tu número'), findsOneWidget);
    expect(find.text('+57 '), findsOneWidget);
    expect(
      find.textContaining('Firebase enviará y almacenará'),
      findsOneWidget,
    );
  });
}
