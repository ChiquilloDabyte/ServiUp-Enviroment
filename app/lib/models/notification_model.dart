import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.payload = const {},
    this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final bool read;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;

  factory AppNotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return AppNotificationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      payload: Map<String, dynamic>.from(data['payload'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'read': read,
      'payload': payload,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
