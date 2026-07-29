import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exception.dart';
import '../../core/logger/app_logger.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.warning('Sign in failed', e);
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.warning('Sign up failed', e);
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión.');
    }
    if (user.emailVerified) return;

    try {
      await _auth.setLanguageCode('es');
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  Future<User?> reloadCurrentUser() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  Future<void> refreshIdToken() async {
    try {
      await _auth.currentUser?.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  Future<void> startPhoneVerification({
    required String phoneNumber,
    required FutureOr<void> Function() onVerificationCompleted,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthException error) onVerificationFailed,
    required void Function(String verificationId) onAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _auth.setLanguageCode('es');
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) {
        unawaited(
          _completePhoneCredential(credential)
              .then((_) => onVerificationCompleted())
              .catchError((Object error, StackTrace stackTrace) {
                AppLogger.warning(
                  'Automatic phone verification failed',
                  error,
                  stackTrace,
                );
                onVerificationFailed(_asAuthException(error));
              }),
        );
      },
      verificationFailed: (error) {
        onVerificationFailed(
          AuthException(_mapAuthError(error), code: error.code),
        );
      },
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onAutoRetrievalTimeout,
    );
  }

  Future<void> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _completePhoneCredential(credential);
  }

  Future<void> _completePhoneCredential(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión.');
    }

    try {
      final phoneAlreadyLinked = user.providerData.any(
        (profile) => profile.providerId == 'phone',
      );
      if (phoneAlreadyLinked) {
        await user.updatePhoneNumber(credential);
      } else {
        await user.linkWithCredential(credential);
      }
      await user.reload();
      await user.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  AuthException _asAuthException(Object error) {
    if (error is AuthException) return error;
    if (error is FirebaseAuthException) {
      return AuthException(_mapAuthError(error), code: error.code);
    }
    return const AuthException(
      'No se pudo verificar el teléfono. Intenta de nuevo.',
    );
  }

  String _mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => 'No existe una cuenta con este correo.',
      'wrong-password' => 'Contraseña incorrecta.',
      'email-already-in-use' => 'Este correo ya está registrado.',
      'weak-password' => 'La contraseña es muy débil.',
      'invalid-email' => 'Correo electrónico inválido.',
      'invalid-credential' => 'Credenciales inválidas.',
      'invalid-phone-number' => 'Ingresa un celular colombiano válido.',
      'invalid-verification-code' => 'El código ingresado no es válido.',
      'session-expired' => 'El código venció. Solicita uno nuevo.',
      'quota-exceeded' =>
        'Se alcanzó el límite temporal de mensajes. Intenta más tarde.',
      'too-many-requests' =>
        'Hiciste demasiados intentos. Espera antes de volver a intentar.',
      'credential-already-in-use' =>
        'Este teléfono ya está asociado a otra cuenta.',
      'provider-already-linked' => 'La cuenta ya tiene un teléfono asociado.',
      'requires-recent-login' =>
        'Por seguridad, cierra sesión e ingresa de nuevo antes de cambiar el teléfono.',
      _ => 'Error de autenticación. Intenta de nuevo.',
    };
  }
}
