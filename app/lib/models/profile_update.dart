import 'package:cloud_firestore/cloud_firestore.dart';

/// Fields a signed-in user is allowed to change on their own profile.
class ProfileUpdate {
  const ProfileUpdate({
    required this.name,
    required this.phone,
    required this.serviceCategories,
    this.photoUrl,
    this.latitude,
    this.longitude,
  });

  final String name;
  final String phone;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final List<String> serviceCategories;

  Map<String, dynamic> toFirestore() {
    final location =
        latitude == null || longitude == null
            ? null
            : GeoPoint(latitude!, longitude!);
    return {
      'name': name.trim(),
      'phone': phone.trim(),
      'photoUrl': photoUrl,
      'serviceCategories': serviceCategories,
      'profileComplete': true,
      if (location != null) 'location': location,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
