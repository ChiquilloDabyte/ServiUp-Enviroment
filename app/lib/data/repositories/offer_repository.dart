import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logger/app_logger.dart';
import '../../models/offer_model.dart';
import '../services/analytics_service.dart';
import '../services/cloud_functions_service.dart';
import '../services/firestore_service.dart';
import 'chat_repository.dart';

class OfferRepository {
  OfferRepository({
    required FirestoreService firestoreService,
    required CloudFunctionsService cloudFunctionsService,
    required AnalyticsService analyticsService,
  }) : _firestoreService = firestoreService,
       _cloudFunctionsService = cloudFunctionsService,
       _analyticsService = analyticsService;

  final FirestoreService _firestoreService;
  final CloudFunctionsService _cloudFunctionsService;
  final AnalyticsService _analyticsService;

  Stream<List<OfferModel>> watchOffersForRequest(String requestId) {
    return _firestoreService.offers
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.defaultPageSize)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(OfferModel.fromFirestore).toList(),
        );
  }

  Stream<List<OfferModel>> watchOffersForChat(String chatId) async* {
    final chat = await _firestoreService.chats.doc(chatId).get();
    final data = chat.data();
    if (data == null) {
      yield const [];
      return;
    }
    final requestId = data['requestId'] as String;
    final providerId = data['providerId'] as String;
    yield* _firestoreService.offers
        .where('requestId', isEqualTo: requestId)
        .where('providerId', isEqualTo: providerId)
        .limit(AppConstants.defaultPageSize)
        .snapshots()
        .map((snapshot) {
          final offers =
              snapshot.docs
                  .map(OfferModel.fromFirestore)
                  .where(
                    (offer) => offer.chatId.isEmpty || offer.chatId == chatId,
                  )
                  .toList()
                ..sort((a, b) => b.revision.compareTo(a.revision));
          return offers;
        });
  }

  Stream<List<OfferModel>> watchProviderOffers(String providerId) {
    return _firestoreService.offers
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.defaultPageSize)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(OfferModel.fromFirestore).toList(),
        );
  }

  Future<String> createOffer({
    required String requestId,
    required String providerId,
    required double proposedPrice,
    required String message,
  }) {
    return _createProposal(
      requestId: requestId,
      providerId: providerId,
      chatId: ChatRepository.chatIdFor(requestId, providerId),
      proposedPrice: proposedPrice,
      conditions: message,
    );
  }

  Future<String> createProposal({
    required String chatId,
    required String actorId,
    required String actorRole,
    required double proposedPrice,
    required String conditions,
  }) {
    return _createProposal(
      chatId: chatId,
      proposedPrice: proposedPrice,
      conditions: conditions,
    );
  }

  Future<String> _createProposal({
    required String chatId,
    required double proposedPrice,
    required String conditions,
    String? requestId,
    String? providerId,
  }) async {
    if (proposedPrice <= 0) {
      throw const RepositoryException('El precio debe ser mayor a cero.');
    }
    final response = await _cloudFunctionsService.call('createProposal', {
      'chatId': chatId,
      'proposedPrice': proposedPrice,
      'conditions': conditions.trim(),
      if (requestId != null) 'requestId': requestId,
      if (providerId != null) 'providerId': providerId,
    });
    try {
      await _analyticsService.logOfferSent(
        response['requestId'] as String? ?? requestId ?? '',
      );
    } catch (error, stackTrace) {
      AppLogger.warning('Offer analytics failed', error, stackTrace);
    }
    return response['offerId'] as String;
  }

  Future<void> acceptOffer({
    required OfferModel offer,
    required String actorId,
  }) {
    if (offer.createdById == actorId) {
      throw const RepositoryException('No puedes aceptar tu propia propuesta.');
    }
    return _cloudFunctionsService
        .call('acceptOffer', {'offerId': offer.id})
        .then((_) {});
  }

  Future<void> rejectOffer({
    required OfferModel offer,
    required String actorId,
  }) {
    if (offer.createdById == actorId) {
      throw const RepositoryException(
        'No puedes rechazar tu propia propuesta.',
      );
    }
    return _cloudFunctionsService
        .call('rejectOffer', {'offerId': offer.id})
        .then((_) {});
  }

  Future<void> markInProgress(String requestId, String providerId) {
    return _transition(requestId, 'start');
  }

  Future<void> requestCompletion(String requestId, String providerId) {
    return _transition(requestId, 'request_completion');
  }

  Future<void> confirmCompletion(String requestId) {
    return _transition(requestId, 'confirm_completion');
  }

  Future<void> returnToProgress(String requestId, String reason) {
    final trimmed = reason.trim();
    if (trimmed.length < 10 || trimmed.length > 500) {
      throw const RepositoryException(
        'El motivo debe tener entre 10 y 500 caracteres.',
      );
    }
    return _transition(requestId, 'return_to_progress', reason: trimmed);
  }

  Future<void> _transition(String requestId, String action, {String? reason}) {
    return _cloudFunctionsService
        .call('transitionServiceRequest', {
          'requestId': requestId,
          'action': action,
          if (reason != null) 'reason': reason,
        })
        .then((_) {});
  }
}
