import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../models/offer_model.dart';
import '../providers/app_providers.dart';

class OfferViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> sendOffer({
    required String requestId,
    required String providerId,
    required double proposedPrice,
    required String message,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(offerRepositoryProvider)
          .createOffer(
            requestId: requestId,
            providerId: providerId,
            proposedPrice: proposedPrice,
            message: message,
          );
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> acceptOffer({
    required OfferModel offer,
    required String actorId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(offerRepositoryProvider)
          .acceptOffer(offer: offer, actorId: actorId);
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> rejectOffer({
    required OfferModel offer,
    required String actorId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(offerRepositoryProvider)
          .rejectOffer(offer: offer, actorId: actorId);
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> createProposal({
    required String chatId,
    required String actorId,
    required String actorRole,
    required double proposedPrice,
    required String conditions,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(offerRepositoryProvider)
          .createProposal(
            chatId: chatId,
            actorId: actorId,
            actorRole: actorRole,
            proposedPrice: proposedPrice,
            conditions: conditions,
          );
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> markInProgress({
    required String requestId,
    required String providerId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(offerRepositoryProvider)
          .markInProgress(requestId, providerId);
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> markCompleted({
    required String requestId,
    required String providerId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(offerRepositoryProvider)
          .markCompleted(requestId, providerId);
    });
    if (state.hasError) throw state.error!;
  }
}

final offerViewModelProvider =
    NotifierProvider<OfferViewModel, AsyncValue<void>>(OfferViewModel.new);

final requestOffersProvider = StreamProvider.autoDispose
    .family<List<OfferModel>, String>((ref, requestId) {
      return ref
          .watch(offerRepositoryProvider)
          .watchOffersForRequest(requestId);
    });

final providerOffersProvider = StreamProvider.autoDispose
    .family<List<OfferModel>, String>((ref, providerId) {
      return ref.watch(offerRepositoryProvider).watchProviderOffers(providerId);
    });

final chatOffersProvider = StreamProvider.autoDispose
    .family<List<OfferModel>, String>((ref, chatId) {
      return ref.watch(offerRepositoryProvider).watchOffersForChat(chatId);
    });

String offerErrorMessage(Object error) {
  if (error is AppException) return error.message;
  return 'No se pudo procesar la oferta.';
}
