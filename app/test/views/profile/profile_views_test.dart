import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/domain/providers/app_providers.dart';
import 'package:serviup/models/account_verification_state.dart';
import 'package:serviup/models/enums/user_role.dart';
import 'package:serviup/models/user_model.dart';
import 'package:serviup/views/profile/edit_profile_view.dart';
import 'package:serviup/views/profile/profile_view.dart';

void main() {
  const provider = UserModel(
    id: 'provider-1',
    email: 'ana@example.com',
    role: UserRole.provider,
    name: 'Ana Torres',
    phone: '+573001234567',
    serviceCategories: ['Plomería'],
    rating: 4.8,
    ratingCount: 12,
    profileComplete: true,
  );

  testWidgets('el perfil muestra datos, servicios y agregado de calificación', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(provider),
          ),
          accountVerificationProvider.overrideWithValue(
            const AccountVerificationState(
              role: UserRole.provider,
              profileComplete: true,
              emailVerified: true,
              phoneVerified: true,
            ),
          ),
        ],
        child: const MaterialApp(home: ProfileView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Torres'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('Plomería'), findsOneWidget);
    expect(find.text('4.8 (12)'), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
  });

  testWidgets('la edición conserva categorías y expone campos editables', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(provider),
          ),
        ],
        child: const MaterialApp(home: EditProfileView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Ana Torres'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '+573001234567'), findsNothing);
    final category = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Plomería'),
    );
    expect(category.selected, isTrue);
  });
}
