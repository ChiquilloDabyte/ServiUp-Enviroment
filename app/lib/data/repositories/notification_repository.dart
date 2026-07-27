import '../../core/constants/app_constants.dart';
import '../../models/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationRepository {
  NotificationRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  Stream<List<AppNotificationModel>> watchUserNotifications(String userId) {
    return _firestoreService.notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.defaultPageSize)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AppNotificationModel.fromFirestore).toList(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestoreService.notifications.doc(notificationId).update({
      'read': true,
    });
  }
}
