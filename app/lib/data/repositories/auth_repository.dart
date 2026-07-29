import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exception.dart';
import '../../core/logger/app_logger.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class AuthRepository {
  AuthRepository({
    required AuthService authService,
    required FirestoreService firestoreService,
    required NotificationService notificationService,
    required AnalyticsService analyticsService,
    StorageService? storageService,
  }) : _authService = authService,
       _firestoreService = firestoreService,
       _notificationService = notificationService,
       _analyticsService = analyticsService,
       _storageService = storageService ?? StorageService();

  final AuthService _authService;
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;
  final AnalyticsService _analyticsService;
  final StorageService _storageService;

  Stream<User?> authStateChanges() => _authService.authStateChanges();

  User? get currentUser => _authService.currentUser;

  Future<void> signIn(String email, String password) async {
    await _authService.signIn(email: email, password: password);
    await syncFcmToken();
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final credential = await _authService.signUp(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const AuthException('No se pudo crear la cuenta.');
    }

    final model = UserModel(
      id: user.uid,
      email: email.trim(),
      role: role,
      name: '',
      phone: '',
      profileComplete: false,
    );

    try {
      await _firestoreService.users.doc(user.uid).set(model.toFirestore());
    } catch (error, stackTrace) {
      try {
        await _authService.deleteCurrentUser();
      } catch (rollbackError, rollbackStack) {
        AppLogger.error(
          'Could not roll back incomplete sign-up',
          rollbackError,
          rollbackStack,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    try {
      await _analyticsService.logSignUp(role.value);
    } catch (error, stackTrace) {
      AppLogger.warning('Sign-up analytics failed', error, stackTrace);
    }
    try {
      await _authService.sendEmailVerification();
      await _analyticsService.logVerificationEvent('email_verification_sent');
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Initial email verification could not be sent',
        error,
        stackTrace,
      );
    }
    await syncFcmToken();

    return model;
  }

  Future<void> signOut() async {
    final uid = currentUser?.uid;
    if (uid != null) {
      try {
        await Future.wait([
          _clearRemoteFcmToken(uid),
          _deleteLocalFcmToken(),
        ]).timeout(const Duration(seconds: 2));
      } on TimeoutException catch (error, stackTrace) {
        AppLogger.warning(
          'FCM cleanup timed out during sign-out',
          error,
          stackTrace,
        );
      }
    }
    await _authService.signOut();
  }

  Future<void> _clearRemoteFcmToken(String uid) async {
    try {
      await _firestoreService.users.doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (error, stackTrace) {
      AppLogger.warning('Could not clear FCM token', error, stackTrace);
    }
  }

  Future<void> _deleteLocalFcmToken() async {
    try {
      await _notificationService.deleteToken();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Could not delete the local FCM token',
        error,
        stackTrace,
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _authService.sendPasswordResetEmail(email);

  Future<void> sendEmailVerification() async {
    await _authService.sendEmailVerification();
    await _logVerificationEvent('email_verification_sent');
  }

  Future<User?> reloadCurrentUser() async {
    final user = await _authService.reloadCurrentUser();
    if (user?.emailVerified ?? false) {
      await _authService.refreshIdToken();
      await _logVerificationEvent('email_verification_completed');
    }
    return user;
  }

  Future<void> startPhoneVerification({
    required String phoneNumber,
    required FutureOr<void> Function() onVerificationCompleted,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthException error) onVerificationFailed,
    required void Function(String verificationId) onAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _logVerificationEvent('phone_verification_started');
    await _authService.startPhoneVerification(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      onVerificationCompleted: () async {
        try {
          await syncVerifiedPhone();
          await _logVerificationEvent('phone_verification_completed');
          await onVerificationCompleted();
        } catch (error, stackTrace) {
          AppLogger.warning(
            'Automatic phone verification could not be synchronized',
            error,
            stackTrace,
          );
          onVerificationFailed(
            error is AuthException
                ? error
                : const AuthException(
                  'El teléfono se verificó, pero falta sincronizarlo.',
                  code: 'phone-sync-failed',
                ),
          );
        }
      },
      onCodeSent: onCodeSent,
      onVerificationFailed: (error) {
        unawaited(_logVerificationEvent('phone_verification_failed'));
        onVerificationFailed(error);
      },
      onAutoRetrievalTimeout: onAutoRetrievalTimeout,
    );
  }

  Future<void> confirmPhoneVerification({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      await _authService.confirmPhoneCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await syncVerifiedPhone();
      await _logVerificationEvent('phone_verification_completed');
    } catch (_) {
      await _logVerificationEvent('phone_verification_failed');
      rethrow;
    }
  }

  Future<void> syncVerifiedPhone() async {
    await _authService.reloadCurrentUser();
    await _authService.refreshIdToken();
    final user = currentUser;
    final phoneNumber = user?.phoneNumber;
    if (user == null || phoneNumber == null || phoneNumber.isEmpty) {
      throw const AuthException(
        'No hay un teléfono verificado para sincronizar.',
        code: 'phone-not-verified',
      );
    }
    await _firestoreService.users.doc(user.uid).update({
      'phone': phoneNumber,
      'phoneVerifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> syncFcmToken([String? refreshedToken]) async {
    final uid = currentUser?.uid;
    final token = refreshedToken ?? await _notificationService.getToken();
    if (uid == null || token == null) return;

    try {
      await _firestoreService.users.doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      AppLogger.warning('Could not sync FCM token', error, stackTrace);
    }
  }

  Stream<String> get onFcmTokenRefresh => _notificationService.onTokenRefresh;

  Future<String> uploadAvatar(File file) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw const AuthException('Debes iniciar sesión.');
    }
    return _storageService.uploadUserAvatar(userId: uid, file: file);
  }

  Future<void> _logVerificationEvent(String name) async {
    try {
      await _analyticsService.logVerificationEvent(name);
    } catch (error, stackTrace) {
      AppLogger.warning('Verification analytics failed', error, stackTrace);
    }
  }
}
