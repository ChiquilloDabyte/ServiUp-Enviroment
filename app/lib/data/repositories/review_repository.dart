import '../../core/errors/app_exception.dart';
import '../../models/review_model.dart';
import '../services/firestore_service.dart';

class ReviewRepository {
  ReviewRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  Stream<ReviewModel?> watchReview(String requestId) {
    return _firestoreService.reviews.doc(requestId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ReviewModel.fromFirestore(doc);
    });
  }

  Future<void> createReview(ReviewModel review) async {
    if (review.rating < 1 || review.rating > 5) {
      throw const RepositoryException(
        'Selecciona una calificación entre 1 y 5 estrellas.',
      );
    }
    if (review.comment.trim().length > 500) {
      throw const RepositoryException(
        'El comentario no puede superar 500 caracteres.',
      );
    }

    await _firestoreService.reviews
        .doc(review.requestId)
        .set(review.toFirestore());
  }
}
