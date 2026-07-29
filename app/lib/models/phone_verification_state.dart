enum PhoneVerificationPhase {
  input,
  sending,
  codeSent,
  verifying,
  completed,
  error,
}

class PhoneVerificationState {
  const PhoneVerificationState({
    this.phase = PhoneVerificationPhase.input,
    this.phoneNumber,
    this.verificationId,
    this.resendToken,
    this.resendAvailableAt,
    this.errorMessage,
  });

  final PhoneVerificationPhase phase;
  final String? phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final DateTime? resendAvailableAt;
  final String? errorMessage;

  bool get isBusy =>
      phase == PhoneVerificationPhase.sending ||
      phase == PhoneVerificationPhase.verifying;

  PhoneVerificationState copyWith({
    PhoneVerificationPhase? phase,
    String? phoneNumber,
    String? verificationId,
    int? resendToken,
    DateTime? resendAvailableAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PhoneVerificationState(
      phase: phase ?? this.phase,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
