import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums/request_status.dart';

class ServiceRequestModel {
  const ServiceRequestModel({
    required this.id,
    required this.clientId,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.scheduledAt,
    required this.status,
    this.acceptedProviderId,
    this.acceptedOfferId,
    this.price,
    this.createdAt,
  });

  final String id;
  final String clientId;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime scheduledAt;
  final RequestStatus status;
  final String? acceptedProviderId;
  final String? acceptedOfferId;
  final double? price;
  final DateTime? createdAt;

  GeoPoint get location => GeoPoint(latitude, longitude);

  factory ServiceRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final location = data['location'] as GeoPoint?;

    return ServiceRequestModel(
      id: doc.id,
      clientId: data['clientId'] as String? ?? '',
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      latitude: location?.latitude ?? 0,
      longitude: location?.longitude ?? 0,
      address: data['address'] as String? ?? '',
      scheduledAt:
          (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: RequestStatus.fromString(data['status'] as String? ?? 'open'),
      acceptedProviderId: data['acceptedProviderId'] as String?,
      acceptedOfferId: data['acceptedOfferId'] as String?,
      price: (data['price'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'category': category,
      'description': description,
      'location': location,
      'address': address,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': status.value,
      'acceptedProviderId': acceptedProviderId,
      'acceptedOfferId': acceptedOfferId,
      'price': price,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
    };
  }

  ServiceRequestModel copyWith({
    RequestStatus? status,
    String? acceptedProviderId,
    String? acceptedOfferId,
    double? price,
  }) {
    return ServiceRequestModel(
      id: id,
      clientId: clientId,
      category: category,
      description: description,
      latitude: latitude,
      longitude: longitude,
      address: address,
      scheduledAt: scheduledAt,
      status: status ?? this.status,
      acceptedProviderId: acceptedProviderId ?? this.acceptedProviderId,
      acceptedOfferId: acceptedOfferId ?? this.acceptedOfferId,
      price: price ?? this.price,
      createdAt: createdAt,
    );
  }
}
