import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums/offer_status.dart';

class OfferModel {
  const OfferModel({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.proposedPrice,
    required this.message,
    required this.status,
    this.chatId = '',
    this.createdById = '',
    this.createdByRole = 'provider',
    this.revision = 1,
    this.supersedesOfferId,
    this.conditions,
    this.createdAt,
  });

  final String id;
  final String requestId;
  final String providerId;
  final double proposedPrice;
  final String message;
  final OfferStatus status;
  final String chatId;
  final String createdById;
  final String createdByRole;
  final int revision;
  final String? supersedesOfferId;
  final String? conditions;
  final DateTime? createdAt;

  factory OfferModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return OfferModel(
      id: doc.id,
      requestId: data['requestId'] as String? ?? '',
      providerId: data['providerId'] as String? ?? '',
      proposedPrice: (data['proposedPrice'] as num?)?.toDouble() ?? 0,
      message: data['message'] as String? ?? '',
      status: OfferStatus.fromString(data['status'] as String? ?? 'pending'),
      chatId: data['chatId'] as String? ?? '',
      createdById:
          data['createdById'] as String? ?? data['providerId'] as String? ?? '',
      createdByRole: data['createdByRole'] as String? ?? 'provider',
      revision: data['revision'] as int? ?? 1,
      supersedesOfferId: data['supersedesOfferId'] as String?,
      conditions: data['conditions'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'providerId': providerId,
      'proposedPrice': proposedPrice,
      'message': message,
      'status': status.value,
      'chatId': chatId,
      'createdById': createdById,
      'createdByRole': createdByRole,
      'revision': revision,
      'supersedesOfferId': supersedesOfferId,
      'conditions': conditions,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
    };
  }

  OfferModel copyWith({OfferStatus? status}) {
    return OfferModel(
      id: id,
      requestId: requestId,
      providerId: providerId,
      proposedPrice: proposedPrice,
      message: message,
      status: status ?? this.status,
      chatId: chatId,
      createdById: createdById,
      createdByRole: createdByRole,
      revision: revision,
      supersedesOfferId: supersedesOfferId,
      conditions: conditions,
      createdAt: createdAt,
    );
  }
}
