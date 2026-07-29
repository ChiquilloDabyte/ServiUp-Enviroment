import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../models/phone_verification_state.dart';
import '../../utils/phone_number_utils.dart';
import '../providers/app_providers.dart';

class EmailVerificationViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> resend() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(authRepositoryProvider).sendEmailVerification,
    );
    if (state.hasError) throw state.error!;
  }

  Future<bool> refresh() async {
    state = const AsyncLoading();
    var verified = false;
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).reloadCurrentUser();
      verified = user?.emailVerified ?? false;
    });
    if (state.hasError) throw state.error!;
    return verified;
  }
}

final emailVerificationViewModelProvider =
    NotifierProvider<EmailVerificationViewModel, AsyncValue<void>>(
      EmailVerificationViewModel.new,
    );

class PhoneVerificationViewModel extends Notifier<PhoneVerificationState> {
  @override
  PhoneVerificationState build() => const PhoneVerificationState();

  Future<void> start(String rawPhoneNumber, {bool resend = false}) async {
    final phoneNumber = normalizeColombianMobile(rawPhoneNumber);
    if (resend) {
      final availableAt = state.resendAvailableAt;
      if (availableAt != null && DateTime.now().isBefore(availableAt)) {
        return;
      }
    }

    final previous = state;
    state = PhoneVerificationState(
      phase: PhoneVerificationPhase.sending,
      phoneNumber: phoneNumber,
      verificationId: previous.verificationId,
      resendToken: previous.resendToken,
    );

    try {
      await ref
          .read(authRepositoryProvider)
          .startPhoneVerification(
            phoneNumber: phoneNumber,
            forceResendingToken: resend ? previous.resendToken : null,
            onVerificationCompleted: () {
              state = state.copyWith(
                phase: PhoneVerificationPhase.completed,
                clearError: true,
              );
            },
            onCodeSent: (verificationId, resendToken) {
              state = PhoneVerificationState(
                phase: PhoneVerificationPhase.codeSent,
                phoneNumber: phoneNumber,
                verificationId: verificationId,
                resendToken: resendToken,
                resendAvailableAt: DateTime.now().add(
                  const Duration(seconds: 60),
                ),
              );
            },
            onVerificationFailed: (error) {
              state = state.copyWith(
                phase: PhoneVerificationPhase.error,
                errorMessage: error.message,
              );
            },
            onAutoRetrievalTimeout: (verificationId) {
              if (state.phase == PhoneVerificationPhase.sending) {
                state = PhoneVerificationState(
                  phase: PhoneVerificationPhase.codeSent,
                  phoneNumber: phoneNumber,
                  verificationId: verificationId,
                  resendToken: previous.resendToken,
                  resendAvailableAt: DateTime.now(),
                );
              }
            },
          );
    } catch (error) {
      state = state.copyWith(
        phase: PhoneVerificationPhase.error,
        errorMessage: verificationErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> confirm(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null) {
      throw const AuthException(
        'Solicita un código antes de continuar.',
        code: 'missing-verification-id',
      );
    }
    if (!RegExp(r'^\d{6}$').hasMatch(smsCode.trim())) {
      throw const AuthException(
        'Ingresa el código de seis dígitos.',
        code: 'invalid-verification-code',
      );
    }

    state = state.copyWith(
      phase: PhoneVerificationPhase.verifying,
      clearError: true,
    );
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmPhoneVerification(
            verificationId: verificationId,
            smsCode: smsCode.trim(),
          );
      state = state.copyWith(
        phase: PhoneVerificationPhase.completed,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        phase: PhoneVerificationPhase.codeSent,
        errorMessage: verificationErrorMessage(error),
      );
      rethrow;
    }
  }

  Future<void> syncExistingPhone() async {
    state = state.copyWith(
      phase: PhoneVerificationPhase.verifying,
      clearError: true,
    );
    try {
      await ref.read(authRepositoryProvider).syncVerifiedPhone();
      state = state.copyWith(
        phase: PhoneVerificationPhase.completed,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        phase: PhoneVerificationPhase.error,
        errorMessage: verificationErrorMessage(error),
      );
      rethrow;
    }
  }

  void reset() {
    state = const PhoneVerificationState();
  }
}

final phoneVerificationViewModelProvider =
    NotifierProvider<PhoneVerificationViewModel, PhoneVerificationState>(
      PhoneVerificationViewModel.new,
    );

String verificationErrorMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is FormatException) return error.message.toString();
  return 'No se pudo completar la verificación.';
}
