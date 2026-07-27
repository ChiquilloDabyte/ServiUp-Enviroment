import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/rating_model.dart';
import '../providers/app_providers.dart';

class RatingViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> saveRating(RatingModel rating) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(ratingRepositoryProvider).saveRating(rating);
    });

    if (state.hasError) throw state.error!;
  }
}

final ratingViewModelProvider =
    NotifierProvider<RatingViewModel, AsyncValue<void>>(
  RatingViewModel.new,
);