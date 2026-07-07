import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> collection(String name) {
    return _firestore.collection(name);
  }

  CollectionReference<Map<String, dynamic>> get users =>
      collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get serviceRequests =>
      collection(AppConstants.serviceRequestsCollection);

  CollectionReference<Map<String, dynamic>> get offers =>
      collection(AppConstants.offersCollection);

  CollectionReference<Map<String, dynamic>> get notifications =>
      collection(AppConstants.notificationsCollection);

  Future<void> runBatch(void Function(WriteBatch batch) action) async {
    final batch = _firestore.batch();
    action(batch);
    await batch.commit();
  }
}
