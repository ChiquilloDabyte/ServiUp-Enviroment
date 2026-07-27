import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums/message_type.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    this.text = '',
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;

  factory ChatMessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ChatMessageModel(
      id: doc.id,
      chatId: doc.reference.parent.parent?.id ?? '',
      senderId: data['senderId'] as String? ?? '',
      type: MessageType.fromString(data['type'] as String? ?? 'text'),
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
