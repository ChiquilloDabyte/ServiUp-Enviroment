import 'enums/user_role.dart';
import 'enums/verification_action.dart';

class AccountVerificationState {
  const AccountVerificationState({
    required this.role,
    required this.profileComplete,
    required this.emailVerified,
    required this.phoneVerified,
  });

  final UserRole? role;
  final bool profileComplete;
  final bool emailVerified;
  final bool phoneVerified;

  List<VerificationRequirement> requirementsFor(VerificationAction action) {
    return [
      if (!profileComplete) VerificationRequirement.profile,
      if (!emailVerified) VerificationRequirement.email,
      if (action == VerificationAction.sendOffer && !phoneVerified)
        VerificationRequirement.phone,
    ];
  }

  List<VerificationRequirement> get accountRequirements {
    return [
      if (!profileComplete) VerificationRequirement.profile,
      if (!emailVerified) VerificationRequirement.email,
      if (role == UserRole.provider && !phoneVerified)
        VerificationRequirement.phone,
    ];
  }

  bool isReadyFor(VerificationAction action) => requirementsFor(action).isEmpty;
}
