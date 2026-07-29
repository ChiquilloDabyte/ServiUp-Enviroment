import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/models/account_verification_state.dart';
import 'package:serviup/models/enums/user_role.dart';
import 'package:serviup/models/enums/verification_action.dart';
import 'package:serviup/utils/phone_number_utils.dart';

void main() {
  group('normalización de celular colombiano', () {
    test('convierte formato local y E.164 al valor canónico', () {
      expect(normalizeColombianMobile('300 123 4567'), '+573001234567');
      expect(normalizeColombianMobile('+57 300 123 4567'), '+573001234567');
      expect(localColombianMobile('+573001234567'), '3001234567');
    });

    test('rechaza números que no sean móviles colombianos', () {
      expect(
        () => normalizeColombianMobile('6012345678'),
        throwsFormatException,
      );
      expect(() => normalizeColombianMobile('300123'), throwsFormatException);
    });
  });

  group('requisitos progresivos', () {
    test('cliente no necesita teléfono para publicar', () {
      const state = AccountVerificationState(
        role: UserRole.client,
        profileComplete: true,
        emailVerified: true,
        phoneVerified: false,
      );

      expect(state.isReadyFor(VerificationAction.publishRequest), isTrue);
      expect(
        state.accountRequirements,
        isNot(contains(VerificationRequirement.phone)),
      );
    });

    test('prestador necesita perfil, correo y teléfono para ofertar', () {
      const state = AccountVerificationState(
        role: UserRole.provider,
        profileComplete: false,
        emailVerified: false,
        phoneVerified: false,
      );

      expect(state.requirementsFor(VerificationAction.sendOffer), [
        VerificationRequirement.profile,
        VerificationRequirement.email,
        VerificationRequirement.phone,
      ]);
    });
  });
}
