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

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    final doc = _firestoreService.notifications.doc();
    final notification = AppNotificationModel(
      id: doc.id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      read: false,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await doc.set(notification.toFirestore());
  }
}
