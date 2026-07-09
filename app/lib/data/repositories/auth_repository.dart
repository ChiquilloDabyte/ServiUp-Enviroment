import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exception.dart';
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
    await _saveFcmToken();
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
      createdAt: DateTime.now(),
    );

    await _firestoreService.users.doc(user.uid).set(model.toFirestore());
    await _analyticsService.logSignUp(role.value);
    await _saveFcmToken();

    return model;
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> sendPasswordResetEmail(String email) =>
      _authService.sendPasswordResetEmail(email);

  Future<void> _saveFcmToken() async {
    final uid = currentUser?.uid;
    final token = await _notificationService.getToken();
    if (uid == null || token == null) return;

    await _firestoreService.users.doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  Future<String> uploadAvatar(File file) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      throw const AuthException('Debes iniciar sesión.');
    }
    return _storageService.uploadUserAvatar(userId: uid, file: file);
  }
}
