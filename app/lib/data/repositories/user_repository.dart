import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/app_exception.dart';
import '../../models/enums/user_role.dart';
import '../../models/profile_update.dart';
import '../../models/provider_public_profile_model.dart';
import '../../models/user_model.dart';
import '../services/firestore_service.dart';

class UserRepository {
  UserRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  Stream<UserModel?> watchUser(String userId) {
    return _firestoreService.users
        .doc(userId)
        .snapshots(includeMetadataChanges: true)
        .where((doc) => doc.exists || !doc.metadata.isFromCache)
        .map((doc) {
          if (!doc.exists) return null;
          return UserModel.fromFirestore(doc);
        });
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestoreService.users.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> createMissingProfile({
    required String userId,
    required String email,
    required UserRole role,
  }) async {
    final user = UserModel(
      id: userId,
      email: email.trim(),
      role: role,
      name: '',
      phone: '',
      profileComplete: false,
    );
    final ref = _firestoreService.users.doc(userId);
    return _firestoreService.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) return UserModel.fromFirestore(existing);
      transaction.set(ref, user.toFirestore());
      return user;
    });
  }

  Future<void> updateEditableProfile({
    required String userId,
    required UserRole role,
    required ProfileUpdate update,
  }) async {
    if (update.name.trim().isEmpty || update.phone.trim().isEmpty) {
      throw const RepositoryException('Nombre y teléfono son obligatorios.');
    }
    if (role == UserRole.provider && update.serviceCategories.isEmpty) {
      throw const RepositoryException(
        'Selecciona al menos una categoría de servicio.',
      );
    }

    // await _firestoreService.users.doc(userId).update(update.toFirestore()); This was the previous code
    // Create documents with users phone and validate it to avoid duplicate phones:

    final phone = update.phone.trim();
    final userRef = _firestoreService.users.doc(userId);
    final phoneIndexRef = _firestoreService.phoneIndexes.doc(phone);
        
    await _firestoreService.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final phoneDoc = await transaction.get(phoneIndexRef);

      // Validate if another user has the same phone number
      if (phoneDoc.exists && phoneDoc.data()?['userId'] != userId) {
        throw const RepositoryException(
          'Este número de teléfono ya está registrado.',
        );
      }

      // If the user had another phone number, liberate that previous phone number
      final oldPhone = userSnap.data()?['phone'] as String?;
      if (oldPhone != null && oldPhone.isNotEmpty && oldPhone != phone) {
        final oldPhoneRef = _firestoreService.phoneIndexes.doc(oldPhone);
        transaction.delete(oldPhoneRef);
      }

      transaction.set(phoneIndexRef, {
        'userId': userId,
      });
      transaction.update(userRef, update.toFirestore());
    });
  }

  Future<void> updateFcmToken(String userId, String token) async {
    await _firestoreService.users.doc(userId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  Future<void> clearFcmToken(String userId) async {
    await _firestoreService.users.doc(userId).update({
      'fcmToken': FieldValue.delete(),
    });
  }

  Stream<List<ProviderPublicProfileModel>> watchProviders({int limit = 20}) {
    return _firestoreService.providerPublicProfiles
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(ProviderPublicProfileModel.fromFirestore)
                  .toList(),
        );
  }
}
