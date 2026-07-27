import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return userCredential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
