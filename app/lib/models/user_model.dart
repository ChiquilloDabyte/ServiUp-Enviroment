import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums/user_role.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.phone,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.serviceCategories = const [],
    this.rating = 0,
    this.profileComplete = false,
    this.fcmToken,
    this.createdAt,
  });

  final String id;
  final String email;
  final UserRole role;
  final String name;
  final String phone;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final List<String> serviceCategories;
  final double rating;
  final bool profileComplete;
  final String? fcmToken;
  final DateTime? createdAt;

  bool get isProvider => role == UserRole.provider;

  GeoPoint? get location {
    if (latitude == null || longitude == null) return null;
    return GeoPoint(latitude!, longitude!);
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final location = data['location'] as GeoPoint?;

    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? 'client'),
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      latitude: location?.latitude,
      longitude: location?.longitude,
      serviceCategories: List<String>.from(data['serviceCategories'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      profileComplete: data['profileComplete'] as bool? ?? false,
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role.value,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      if (location != null) 'location': location,
      'serviceCategories': serviceCategories,
      'rating': rating,
      'profileComplete': profileComplete,
      'fcmToken': fcmToken,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    double? latitude,
    double? longitude,
    List<String>? serviceCategories,
    double? rating,
    bool? profileComplete,
    String? fcmToken,
  }) {
    return UserModel(
      id: id,
      email: email,
      role: role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      rating: rating ?? this.rating,
      profileComplete: profileComplete ?? this.profileComplete,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
