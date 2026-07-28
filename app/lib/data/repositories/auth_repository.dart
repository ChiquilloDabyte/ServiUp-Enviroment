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
}
