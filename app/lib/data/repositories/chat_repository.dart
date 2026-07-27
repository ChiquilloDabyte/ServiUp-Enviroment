import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../models/chat_message_model.dart';
import '../../models/chat_model.dart';
import '../../models/enums/chat_status.dart';
import '../../models/enums/message_type.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ChatRepository {
  ChatRepository({
    required FirestoreService firestoreService,
    required StorageService storageService,
  }) : _firestoreService = firestoreService,
       _storageService = storageService;

  final FirestoreService _firestoreService;
  final StorageService _storageService;

  static String chatIdFor(String requestId, String providerId) =>
      '${requestId}_$providerId';

  Future<String> ensureChat({
    required String requestId,
    required String clientId,
    required String providerId,
  }) async {
    final chatId = chatIdFor(requestId, providerId);
    final chatRef = _firestoreService.chats.doc(chatId);
    final users = await Future.wait([
      _firestoreService.users.doc(clientId).get(),
      _firestoreService.users.doc(providerId).get(),
    ]);

    await _firestoreService.runTransaction((transaction) async {
      final existing = await transaction.get(chatRef);
      if (existing.exists) return;
      transaction.set(chatRef, {
        'requestId': requestId,
        'clientId': clientId,
        'providerId': providerId,
        'clientName': users[0].data()?['name'] as String? ?? '',
        'providerName': users[1].data()?['name'] as String? ?? '',
        'status': ChatStatus.active.value,
        'lastMessage': '',
        'lastMessageAt': null,
        'unreadByClient': 0,
        'unreadByProvider': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return chatId;
  }

  Stream<ChatModel?> watchChat(String chatId) {
    return _firestoreService.chats
        .doc(chatId)
        .snapshots()
        .map((doc) => doc.exists ? ChatModel.fromFirestore(doc) : null);
  }

  Stream<List<ChatModel>> watchUserChats(String userId) {
    return _firestoreService.chats
        .where(
          Filter.or(
            Filter('clientId', isEqualTo: userId),
            Filter('providerId', isEqualTo: userId),
          ),
        )
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ChatModel.fromFirestore).toList());
  }

  Stream<List<ChatMessageModel>> watchMessages(
    String chatId, {
    int limit = AppConstants.chatPageSize,
  }) {
    return _firestoreService.chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(ChatMessageModel.fromFirestore)
              .toList()
              .reversed
              .toList();
        });
  }

  Future<void> sendText({
    required ChatModel chat,
    required String senderId,
    required String text,
  }) async {
    final content = text.trim();
    if (content.isEmpty) {
      throw const RepositoryException('Escribe un mensaje.');
    }
    if (content.length > AppConstants.maxChatMessageLength) {
      throw const RepositoryException('El mensaje es demasiado largo.');
    }
    await _sendMessage(
      chat: chat,
      senderId: senderId,
      type: MessageType.text,
      text: content,
    );
  }

  Future<void> sendImage({
    required ChatModel chat,
    required String senderId,
    required File file,
  }) async {
    _validateWritable(chat, senderId);
    final messageRef =
        _firestoreService.chats.doc(chat.id).collection('messages').doc();
    final imageUrl = await _storageService.uploadChatImage(
      chatId: chat.id,
      messageId: messageRef.id,
      file: file,
    );
    await _sendMessage(
      chat: chat,
      senderId: senderId,
      type: MessageType.image,
      text: '',
      imageUrl: imageUrl,
      messageId: messageRef.id,
    );
  }

  Future<void> _sendMessage({
    required ChatModel chat,
    required String senderId,
    required MessageType type,
    required String text,
    String? imageUrl,
    String? messageId,
  }) async {
    _validateWritable(chat, senderId);
    final chatRef = _firestoreService.chats.doc(chat.id);
    final messageRef = chatRef.collection('messages').doc(messageId);
    final unreadField =
        senderId == chat.clientId ? 'unreadByProvider' : 'unreadByClient';

    await _firestoreService.runBatch((batch) {
      batch.set(messageRef, {
        'senderId': senderId,
        'type': type.value,
        'text': text,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(chatRef, {
        'lastMessage': type == MessageType.image ? 'Imagen' : text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        unreadField: FieldValue.increment(1),
      });
    });
  }

  Future<void> markAsRead(ChatModel chat, String userId) {
    _validateParticipant(chat, userId);
    final field =
        userId == chat.clientId ? 'unreadByClient' : 'unreadByProvider';
    return _firestoreService.chats.doc(chat.id).update({field: 0});
  }

  void _validateWritable(ChatModel chat, String userId) {
    _validateParticipant(chat, userId);
    if (chat.status != ChatStatus.active) {
      throw const RepositoryException(
        'Esta conversación está disponible solo para lectura.',
      );
    }
  }

  void _validateParticipant(ChatModel chat, String userId) {
    if (!chat.containsParticipant(userId)) {
      throw const RepositoryException('No puedes acceder a esta conversación.');
    }
  }
}
