import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadUserAvatar({
    required String userId,
    required File file,
  }) async {
    final size = await file.length();
    if (size > AppConstants.maxImageSizeBytes) {
      throw const RepositoryException('La imagen supera el tamaño máximo de 5 MB.');
    }

    final ref = _storage.ref().child('users/$userId/avatar.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
