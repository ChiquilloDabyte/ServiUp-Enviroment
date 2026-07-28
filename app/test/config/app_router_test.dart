import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/config/app_router.dart';

void main() {
  group('resolveAppRedirect', () {
    test('espera el perfil antes de decidir el onboarding', () {
      final redirect = resolveAppRedirect(
        matchedLocation: '/home',
        authState: AuthRouteState.signedIn,
        profileState: ProfileRouteState.loading,
      );

      expect(redirect, isNull);
    });

    test('envía a onboarding cuando el perfil confirmado no existe', () {
      final redirect = resolveAppRedirect(
        matchedLocation: '/home',
        authState: AuthRouteState.signedIn,
        profileState: ProfileRouteState.missing,
      );

      expect(redirect, '/onboarding');
    });

    test('envía a onboarding cuando el perfil está incompleto', () {
      final redirect = resolveAppRedirect(
        matchedLocation: '/home',
        authState: AuthRouteState.signedIn,
        profileState: ProfileRouteState.incomplete,
      );

      expect(redirect, '/onboarding');
    });

    test('sale de onboarding cuando llega el perfil completo', () {
      final redirect = resolveAppRedirect(
        matchedLocation: '/onboarding',
        authState: AuthRouteState.signedIn,
        profileState: ProfileRouteState.complete,
      );

      expect(redirect, '/home');
    });

    test('tras el login espera el perfil y luego entra al home', () {
      final whileLoading = resolveAppRedirect(
        matchedLocation: '/login',
        authState: AuthRouteState.signedIn,
        profileState: ProfileRouteState.loading,
      );
      final whenComplete = resolveAppRedirect(
        matchedLocation: '/login',
        authState: AuthRouteState.signedIn,
        profileState: ProfileRouteState.complete,
      );

      expect(whileLoading, isNull);
      expect(whenComplete, '/home');
    });
  });
}
