import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/chat_viewmodel.dart';
import '../../models/chat_model.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class ChatsView extends ConsumerWidget {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final AsyncValue<List<ChatModel>> chats =
        user == null
            ? const AsyncValue<List<ChatModel>>.loading()
            : ref.watch(userChatsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Conversaciones')),
      body: chats.when(
        loading: () => const ResponsiveContent(child: LoadingView()),
        error:
            (error, _) => ResponsiveContent(
              child: EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No pudimos cargar tus conversaciones',
                message: chatErrorMessage(error),
              ),
            ),
        data: (items) {
          if (items.isEmpty) {
            return const ResponsiveContent(
              child: EmptyState(
                icon: Icons.forum_outlined,
                title: 'Aún no tienes conversaciones',
                message:
                    'Tus conversaciones con clientes y prestadores '
                    'aparecerán aquí.',
              ),
            );
          }

          return ResponsiveContent(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final chat = items[index];
                final unread = user == null ? 0 : chat.unreadFor(user.id);
                final name =
                    user == null
                        ? 'Conversación'
                        : chat.otherParticipantName(user.id);
                final displayName =
                    name.isEmpty ? 'Conversación de servicio' : name;

                return InkWell(
                  borderRadius: AppRadius.card,
                  onTap: () => context.push('/chats/${chat.id}'),
                  child: SectionCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryFixed,
                          foregroundColor:
                              Theme.of(
                                context,
                              ).colorScheme.onPrimaryFixedVariant,
                          child: Text(
                            name.isEmpty
                                ? '?'
                                : name.characters.first.toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.gutter),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                chat.lastMessage.isEmpty
                                    ? 'Oferta enviada'
                                    : chat.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (chat.lastMessageAt != null)
                              Text(
                                formatDateTime(chat.lastMessageAt!),
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (chat.lastMessageAt != null && unread > 0)
                              const SizedBox(height: AppSpacing.xs),
                            if (unread > 0)
                              Semantics(
                                label:
                                    '$unread ${unread == 1 ? 'mensaje no leído' : 'mensajes no leídos'}',
                                child: ExcludeSemantics(
                                  child: Badge(
                                    label: Text(
                                      unread > 99 ? '99+' : '$unread',
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
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
