import '../../core/errors/app_exception.dart';
import '../../models/enums/offer_status.dart';
import '../../models/enums/request_status.dart';
import '../../models/offer_model.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import 'service_request_repository.dart';

class OfferRepository {
  OfferRepository({
    required FirestoreService firestoreService,
    required ServiceRequestRepository serviceRequestRepository,
    required AnalyticsService analyticsService,
  })  : _firestoreService = firestoreService,
        _serviceRequestRepository = serviceRequestRepository,
        _analyticsService = analyticsService;

  final FirestoreService _firestoreService;
  final ServiceRequestRepository _serviceRequestRepository;
  final AnalyticsService _analyticsService;

  Stream<List<OfferModel>> watchOffersForRequest(String requestId) {
    return _firestoreService.offers
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(OfferModel.fromFirestore).toList());
  }

  Stream<List<OfferModel>> watchProviderOffers(String providerId) {
    return _firestoreService.offers
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(OfferModel.fromFirestore).toList());
  }

  Future<String> createOffer({
    required String requestId,
    required String providerId,
    required double proposedPrice,
    required String message,
  }) async {
    if (proposedPrice <= 0) {
      throw const RepositoryException('El precio debe ser mayor a cero.');
    }

    final doc = _firestoreService.offers.doc();
    final offer = OfferModel(
      id: doc.id,
      requestId: requestId,
      providerId: providerId,
      proposedPrice: proposedPrice,
      message: message.trim(),
      status: OfferStatus.pending,
      createdAt: DateTime.now(),
    );

    await doc.set(offer.toFirestore());
    await _analyticsService.logOfferSent(requestId);
    return doc.id;
  }

  Future<void> acceptOffer({
    required OfferModel offer,
    required String clientId,
  }) async {
    final request = await _firestoreService.serviceRequests
        .doc(offer.requestId)
        .get();

    if (!request.exists) {
      throw const RepositoryException('La solicitud ya no existe.');
    }

    final requestData = request.data() ?? {};
    if (requestData['clientId'] != clientId) {
      throw const RepositoryException('No puedes aceptar esta oferta.');
    }

    final otherOffers = await _firestoreService.offers
        .where('requestId', isEqualTo: offer.requestId)
        .where('status', isEqualTo: OfferStatus.pending.value)
        .get();

    await _firestoreService.runBatch((batch) {
      batch.update(_firestoreService.offers.doc(offer.id), {
        'status': OfferStatus.accepted.value,
      });

      for (final doc in otherOffers.docs) {
        if (doc.id != offer.id) {
          batch.update(doc.reference, {
            'status': OfferStatus.rejected.value,
          });
        }
      }

      batch.update(_firestoreService.serviceRequests.doc(offer.requestId), {
        'status': RequestStatus.accepted.value,
        'acceptedProviderId': offer.providerId,
        'price': offer.proposedPrice,
      });
    });
  }

  Future<void> rejectOffer(String offerId) async {
    await _firestoreService.offers.doc(offerId).update({
      'status': OfferStatus.rejected.value,
    });
  }

  Future<void> markInProgress(String requestId, String providerId) {
    return _serviceRequestRepository.updateStatus(
      requestId: requestId,
      status: RequestStatus.inProgress,
      acceptedProviderId: providerId,
    );
  }

  Future<void> markCompleted(String requestId, String providerId) {
    return _serviceRequestRepository.updateStatus(
      requestId: requestId,
      status: RequestStatus.completed,
      acceptedProviderId: providerId,
    );
  }
}
