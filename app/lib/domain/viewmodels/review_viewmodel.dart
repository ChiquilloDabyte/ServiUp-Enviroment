import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../models/enums/request_status.dart';
import '../../models/review_model.dart';
import '../../models/service_request_model.dart';
import '../providers/app_providers.dart';

class ReviewViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createReview({
    required ServiceRequestModel request,
    required String clientId,
    required int rating,
    required String comment,
  }) async {
    if (request.status != RequestStatus.completed ||
        request.clientId != clientId ||
        request.acceptedProviderId == null) {
      throw const RepositoryException(
        'Este servicio todavía no se puede calificar.',
      );
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final review = ReviewModel(
        requestId: request.id,
        clientId: clientId,
        providerId: request.acceptedProviderId!,
        rating: rating,
        comment: comment,
      );
      await ref.read(reviewRepositoryProvider).createReview(review);
    });
    if (state.hasError) throw state.error!;
  }
}

final reviewViewModelProvider =
    NotifierProvider<ReviewViewModel, AsyncValue<void>>(ReviewViewModel.new);

final reviewDetailProvider = StreamProvider.autoDispose
    .family<ReviewModel?, String>((ref, requestId) {
      return ref.watch(reviewRepositoryProvider).watchReview(requestId);
    });

String reviewErrorMessage(Object error) {
  if (error is AppException) return error.message;
  return 'No se pudo guardar la calificación.';
}
