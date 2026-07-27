import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums/chat_status.dart';

class ChatModel {
  const ChatModel({
    required this.id,
    required this.requestId,
    required this.clientId,
    required this.providerId,
    required this.status,
    this.clientName = '',
    this.providerName = '',
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadByClient = 0,
    this.unreadByProvider = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String requestId;
  final String clientId;
  final String providerId;
  final ChatStatus status;
  final String clientName;
  final String providerName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadByClient;
  final int unreadByProvider;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool containsParticipant(String userId) =>
      clientId == userId || providerId == userId;

  String otherParticipantName(String userId) =>
      userId == clientId ? providerName : clientName;

  int unreadFor(String userId) =>
      userId == clientId ? unreadByClient : unreadByProvider;

  factory ChatModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatModel(
      id: doc.id,
      requestId: data['requestId'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      providerId: data['providerId'] as String? ?? '',
      status: ChatStatus.fromString(data['status'] as String? ?? 'active'),
      clientName: data['clientName'] as String? ?? '',
      providerName: data['providerName'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadByClient: data['unreadByClient'] as int? ?? 0,
      unreadByProvider: data['unreadByProvider'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
