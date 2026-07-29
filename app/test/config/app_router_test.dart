import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/config/app_router.dart';
import 'package:serviup/models/enums/user_role.dart';

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

    test('permite explorar cuando el perfil está incompleto', () {
      final redirect = resolveAppRedirect(
        matchedLocation: '/home',
        authState: AuthRouteState.signedIn,
        profileState: ProfileRouteState.incomplete,
      );

      expect(redirect, isNull);
    });

    test('onboarding controla su propia salida al completarse', () {
      final redirect = resolveAppRedirect(
        matchedLocation: '/onboarding',
        authState: AuthRouteState.signedIn,
        profileState: ProfileRouteState.complete,
      );

      expect(redirect, isNull);
    });

    test('login controla la navegación después de autenticar', () {
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
      expect(whenComplete, isNull);
    });

    test('impide que un prestador abra el directorio offline', () {
      final redirect = resolveAppRedirect(
        matchedLocation: '/offline',
        authState: AuthRouteState.signedIn,
        profileState: ProfileRouteState.complete,
        userRole: UserRole.provider,
      );

      expect(redirect, '/home');
    });

    test('permite que un cliente abra el directorio offline', () {
      final redirect = resolveAppRedirect(
        matchedLocation: '/offline',
        authState: AuthRouteState.signedIn,
        profileState: ProfileRouteState.complete,
        userRole: UserRole.client,
      );

      expect(redirect, isNull);
    });
  });
}
