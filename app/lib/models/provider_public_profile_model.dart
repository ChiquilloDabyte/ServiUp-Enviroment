import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderPublicProfileModel {
  const ProviderPublicProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.serviceCategories,
    required this.rating,
    required this.ratingCount,
    this.photoUrl,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final List<String> serviceCategories;
  final double rating;
  final int ratingCount;
  final DateTime? updatedAt;

  factory ProviderPublicProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ProviderPublicProfileModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      serviceCategories: List<String>.from(
        data['serviceCategories'] as List? ?? const [],
      ),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: data['ratingCount'] as int? ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
