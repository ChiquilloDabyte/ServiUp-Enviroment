import '../../models/rating_model.dart';
import '../services/firestore_service.dart';

class RatingRepository {
  RatingRepository({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  Future<void> saveRating(RatingModel rating) async {
    await _firestoreService.ratings.add(
      rating.toFirestore(),
    );
  }

  // <-- AGREGA ESTE MÉTODO
  Stream<Map<String, dynamic>> watchProviderRating(String providerId) {
    return _firestoreService.ratings
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return {
          'average': 0.0,
          'count': 0,
        };
      }

      double total = 0;

      for (final doc in snapshot.docs) {
        total += (doc.data()['rating'] as num).toDouble();
      }

      return {
        'average': total / snapshot.docs.length,
        'count': snapshot.docs.length,
      };
    });
  }
}