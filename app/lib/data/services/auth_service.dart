import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exception.dart';
import '../../core/logger/app_logger.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

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

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => 'No existe una cuenta con este correo.',
      'wrong-password' => 'Contraseña incorrecta.',
      'email-already-in-use' => 'Este correo ya está registrado.',
      'weak-password' => 'La contraseña es muy débil.',
      'invalid-email' => 'Correo electrónico inválido.',
      'invalid-credential' => 'Credenciales inválidas.',
      _ => 'Error de autenticación. Intenta de nuevo.',
    };
  }
}
