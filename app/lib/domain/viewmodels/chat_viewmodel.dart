import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../models/chat_message_model.dart';
import '../../models/chat_model.dart';
import '../providers/app_providers.dart';

class ChatViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String> ensureChat({
    required String requestId,
    required String clientId,
    required String providerId,
  }) {
    return ref
        .read(chatRepositoryProvider)
        .ensureChat(
          requestId: requestId,
          clientId: clientId,
          providerId: providerId,
        );
  }

  Future<void> sendText({
    required ChatModel chat,
    required String senderId,
    required String text,
  }) async {
    await _runOnline(() {
      return ref
          .read(chatRepositoryProvider)
          .sendText(chat: chat, senderId: senderId, text: text);
    });
  }

  Future<void> sendImage({
    required ChatModel chat,
    required String senderId,
    required File file,
  }) async {
    await _runOnline(() {
      return ref
          .read(chatRepositoryProvider)
          .sendImage(chat: chat, senderId: senderId, file: file);
    });
  }

  Future<void> markAsRead(ChatModel chat, String userId) {
    return ref.read(chatRepositoryProvider).markAsRead(chat, userId);
  }

  Future<void> _runOnline(Future<void> Function() action) async {
    final hasConnection =
        await ref.read(connectivityServiceProvider).hasConnection();
    if (!hasConnection) {
      throw const RepositoryException(
        'Necesitas conexión para enviar mensajes.',
      );
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    if (state.hasError) throw state.error!;
  }
}

final chatViewModelProvider = NotifierProvider<ChatViewModel, AsyncValue<void>>(
  ChatViewModel.new,
);

final chatDetailProvider = StreamProvider.autoDispose
    .family<ChatModel?, String>((ref, chatId) {
      return ref.watch(chatRepositoryProvider).watchChat(chatId);
    });

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessageModel>, String>((ref, chatId) {
      return ref.watch(chatRepositoryProvider).watchMessages(chatId);
    });

final chatMessagePageProvider = StreamProvider.autoDispose
    .family<List<ChatMessageModel>, ({String chatId, int limit})>((
      ref,
      params,
    ) {
      return ref
          .watch(chatRepositoryProvider)
          .watchMessages(params.chatId, limit: params.limit);
    });

final userChatsProvider = StreamProvider.autoDispose
    .family<List<ChatModel>, String>((ref, userId) {
      return ref.watch(chatRepositoryProvider).watchUserChats(userId);
    });

String chatErrorMessage(Object error) {
  if (error is AppException) return error.message;
  return 'No se pudo completar la acción en la conversación.';
}
