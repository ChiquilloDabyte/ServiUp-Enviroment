import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/chat_viewmodel.dart';
import '../../models/chat_model.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_view.dart';

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
        loading: () => const LoadingView(),
        error: (error, _) => Center(child: Text(chatErrorMessage(error))),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Aún no tienes conversaciones.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = items[index];
              final unread = user == null ? 0 : chat.unreadFor(user.id);
              final name =
                  user == null
                      ? 'Conversación'
                      : chat.otherParticipantName(user.id);
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  ),
                ),
                title: Text(name.isEmpty ? 'Conversación de servicio' : name),
                subtitle: Text(
                  chat.lastMessage.isEmpty
                      ? 'Oferta enviada'
                      : chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (chat.lastMessageAt != null)
                      Text(
                        formatDateTime(chat.lastMessageAt!),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    if (unread > 0)
                      Badge(label: Text(unread > 99 ? '99+' : '$unread')),
                  ],
                ),
                onTap: () => context.push('/chats/${chat.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
