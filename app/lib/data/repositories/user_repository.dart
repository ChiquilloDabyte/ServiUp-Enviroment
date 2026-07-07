import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/app_exception.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../services/firestore_service.dart';

class UserRepository {
  UserRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  Stream<UserModel?> watchUser(String userId) {
    return _firestoreService.users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestoreService.users.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> saveProfile(UserModel user) async {
    if (user.name.trim().isEmpty || user.phone.trim().isEmpty) {
      throw const RepositoryException('Nombre y teléfono son obligatorios.');
    }

    if (user.role == UserRole.provider && user.serviceCategories.isEmpty) {
      throw const RepositoryException(
        'Selecciona al menos una categoría de servicio.',
      );
    }

    final updated = user.copyWith(profileComplete: true);
    await _firestoreService.users.doc(user.id).set(
          updated.toFirestore(),
          SetOptions(merge: true),
        );
  }

  Future<void> updateFcmToken(String userId, String token) async {
    await _firestoreService.users.doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  Stream<List<UserModel>> watchProviders() {
    return _firestoreService.users
        .where('role', isEqualTo: UserRole.provider.value)
        .where('profileComplete', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(UserModel.fromFirestore).toList(),
        );
  }
}
