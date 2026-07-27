import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/notification_viewmodel.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    if (user == null) {
      return const Scaffold(
        body: ResponsiveContent(
          child: EmptyState(
            icon: Icons.person_off_outlined,
            title: 'Sin sesión',
            message: 'Inicia sesión para ver tus notificaciones.',
          ),
        ),
      );
    }

    final notifications = ref.watch(userNotificationsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: notifications.when(
        loading: () => const ResponsiveContent(child: LoadingView()),
        error:
            (error, _) => ResponsiveContent(
              child: EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'No pudimos cargar las notificaciones',
                message: error.toString(),
              ),
            ),
        data: (items) {
          if (items.isEmpty) {
            return const ResponsiveContent(
              child: EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'No tienes notificaciones',
                message: 'Las novedades sobre tus servicios aparecerán aquí.',
              ),
            );
          }

          return ResponsiveContent(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder:
                  (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final notification = items[index];
                return InkWell(
                  borderRadius: AppRadius.card,
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
                  child: SectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                notification.body,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (notification.createdAt != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  formatDateTime(notification.createdAt!),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!notification.read) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Semantics(
                            label: 'Notificación no leída',
                            child: ExcludeSemantics(
                              child: Icon(
                                Icons.fiber_manual_record,
                                size: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
