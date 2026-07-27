import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  User? _user;

  User? get user => _user;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _authRepository.signInWithEmailAndPassword(email, password);
      _user = User.fromFirestore(userCredential.user!.toMap());
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _user = null;
    notifyListeners();
  }
}
