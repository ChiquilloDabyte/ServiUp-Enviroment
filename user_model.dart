import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    return User(
      id: doc.id,
      name: doc['name'],
      email: doc['email'],
      role: UserRole.fromString(doc['role']),
    );
  }
}
