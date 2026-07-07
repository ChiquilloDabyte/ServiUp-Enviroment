import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_model.dart';
import '../providers/app_providers.dart';

final userNotificationsProvider =
    StreamProvider.family<List<AppNotificationModel>, String>((ref, userId) {
  return ref
      .watch(notificationRepositoryProvider)
      .watchUserNotifications(userId);
});

class NotificationActions {
  NotificationActions(this.ref);

  final Ref ref;

  Future<void> markAsRead(String notificationId) {
    return ref
        .read(notificationRepositoryProvider)
        .markAsRead(notificationId);
  }
}

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});
