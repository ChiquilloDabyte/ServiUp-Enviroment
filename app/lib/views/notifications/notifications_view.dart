import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/notification_viewmodel.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_view.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sin sesión')));
    }

    final notifications = ref.watch(userNotificationsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: notifications.when(
        loading: () => const LoadingView(),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No tienes notificaciones.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = items[index];
              return Card(
                child: ListTile(
                  title: Text(notification.title),
                  subtitle: Text(notification.body),
                  trailing:
                      notification.read
                          ? null
                          : const Icon(Icons.fiber_manual_record, size: 12),
                  onTap: () async {
                    await ref
                        .read(notificationActionsProvider)
                        .markAsRead(notification.id);

                    final chatId = notification.payload['chatId'];
                    final requestId = notification.payload['requestId'];
                    if (chatId is String &&
                        chatId.isNotEmpty &&
                        context.mounted) {
                      context.push('/chats/$chatId');
                    } else if (requestId is String && context.mounted) {
                      context.push('/requests/$requestId');
                    }
                  },
                  leading: Text(
                    notification.createdAt == null
                        ? ''
                        : formatDateTime(notification.createdAt!),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
