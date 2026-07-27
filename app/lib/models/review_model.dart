import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  const ReviewModel({
    required this.requestId,
    required this.clientId,
    required this.providerId,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  final String requestId;
  final String clientId;
  final String providerId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  factory ReviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ReviewModel(
      requestId: data['requestId'] as String? ?? doc.id,
      clientId: data['clientId'] as String? ?? '',
      providerId: data['providerId'] as String? ?? '',
      rating: data['rating'] as int? ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'clientId': clientId,
      'providerId': providerId,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
