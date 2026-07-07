import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../providers/app_providers.dart';

class AuthViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signIn(email, password);
    });
    if (state.hasError) throw state.error!;
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    late UserModel user;
    state = await AsyncValue.guard(() async {
      user = await ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
            role: role,
          );
    });
    if (state.hasError) throw state.error!;
    return user;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
    });
    if (state.hasError) throw state.error!;
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AsyncValue<void>>(AuthViewModel.new);

class UserViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> saveProfile({
    required UserModel user,
    required String name,
    required String phone,
    required List<String> categories,
    double? latitude,
    double? longitude,
    File? avatarFile,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      var photoUrl = user.photoUrl;
      if (avatarFile != null) {
        photoUrl = await ref.read(authRepositoryProvider).uploadAvatar(avatarFile);
      }

      final updated = user.copyWith(
        name: name.trim(),
        phone: phone.trim(),
        serviceCategories: categories,
        latitude: latitude,
        longitude: longitude,
        photoUrl: photoUrl,
      );

      await ref.read(userRepositoryProvider).saveProfile(updated);
    });

    if (state.hasError) throw state.error!;
  }
}

final userViewModelProvider =
    NotifierProvider<UserViewModel, AsyncValue<void>>(UserViewModel.new);

String authErrorMessage(Object error) {
  if (error is AppException) return error.message;
  return 'Ocurrió un error inesperado.';
}
