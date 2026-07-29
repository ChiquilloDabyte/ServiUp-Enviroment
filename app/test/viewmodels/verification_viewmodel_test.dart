import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/errors/app_exception.dart';
import 'package:serviup/data/repositories/auth_repository.dart';
import 'package:serviup/domain/providers/app_providers.dart';
import 'package:serviup/domain/viewmodels/verification_viewmodel.dart';
import 'package:serviup/models/phone_verification_state.dart';

class _FakeAuthRepository implements AuthRepository {
  var starts = 0;
  var confirmations = 0;
  var synchronizations = 0;
  var emailResends = 0;
  var completeAutomatically = false;
  AuthException? confirmationError;

  @override
  Future<void> sendEmailVerification() async {
    emailResends++;
  }

  @override
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required FutureOr<void> Function() onVerificationCompleted,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthException error) onVerificationFailed,
    required void Function(String verificationId) onAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    starts++;
    if (completeAutomatically) {
      await onVerificationCompleted();
      return;
    }
    onCodeSent('verification-id', 42);
  }

  @override
  Future<void> confirmPhoneVerification({
    required String verificationId,
    required String smsCode,
  }) async {
    confirmations++;
    final error = confirmationError;
    if (error != null) throw error;
  }

  @override
  Future<void> syncVerifiedPhone() async {
    synchronizations++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container(_FakeAuthRepository repository) {
  return ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
}

void main() {
  test('el correo puede reenviarse desde el ViewModel', () async {
    final repository = _FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    await container.read(emailVerificationViewModelProvider.notifier).resend();

    expect(repository.emailResends, 1);
    expect(
      container.read(emailVerificationViewModelProvider),
      isA<AsyncData<void>>(),
    );
  });

  test('el reenvío de SMS respeta la espera de 60 segundos', () async {
    final repository = _FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final notifier = container.read(
      phoneVerificationViewModelProvider.notifier,
    );

    await notifier.start('3001234567');
    await notifier.start('3001234567', resend: true);

    expect(repository.starts, 1);
    final state = container.read(phoneVerificationViewModelProvider);
    expect(state.phase, PhoneVerificationPhase.codeSent);
    expect(state.resendToken, 42);
    expect(state.resendAvailableAt, isNotNull);
  });

  test(
    'un código inválido conserva la sesión para volver a intentar',
    () async {
      final repository =
          _FakeAuthRepository()
            ..confirmationError = const AuthException(
              'El código ingresado no es válido.',
              code: 'invalid-verification-code',
            );
      final container = _container(repository);
      addTearDown(container.dispose);
      final notifier = container.read(
        phoneVerificationViewModelProvider.notifier,
      );
      await notifier.start('3001234567');

      await expectLater(
        notifier.confirm('123456'),
        throwsA(isA<AuthException>()),
      );

      final state = container.read(phoneVerificationViewModelProvider);
      expect(state.phase, PhoneVerificationPhase.codeSent);
      expect(state.verificationId, 'verification-id');
      expect(state.errorMessage, 'El código ingresado no es válido.');
    },
  );

  test('la verificación automática completa el flujo', () async {
    final repository = _FakeAuthRepository()..completeAutomatically = true;
    final container = _container(repository);
    addTearDown(container.dispose);

    await container
        .read(phoneVerificationViewModelProvider.notifier)
        .start('3001234567');

    expect(
      container.read(phoneVerificationViewModelProvider).phase,
      PhoneVerificationPhase.completed,
    );
  });

  test('un teléfono ya vinculado se resincroniza sin otro SMS', () async {
    final repository = _FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    await container
        .read(phoneVerificationViewModelProvider.notifier)
        .syncExistingPhone();

    expect(repository.synchronizations, 1);
    expect(repository.starts, 0);
    expect(
      container.read(phoneVerificationViewModelProvider).phase,
      PhoneVerificationPhase.completed,
    );
  });
}
