import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/app_exception.dart';
import '../../models/enums/chat_status.dart';
import '../../models/enums/offer_status.dart';
import '../../models/enums/request_status.dart';
import '../../models/offer_model.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import 'chat_repository.dart';
import 'service_request_repository.dart';

class OfferRepository {
  OfferRepository({
    required FirestoreService firestoreService,
    required ServiceRequestRepository serviceRequestRepository,
    required ChatRepository chatRepository,
    required AnalyticsService analyticsService,
  }) : _firestoreService = firestoreService,
       _serviceRequestRepository = serviceRequestRepository,
       _chatRepository = chatRepository,
       _analyticsService = analyticsService;

  final FirestoreService _firestoreService;
  final ServiceRequestRepository _serviceRequestRepository;
  final ChatRepository _chatRepository;
  final AnalyticsService _analyticsService;

  Stream<List<OfferModel>> watchOffersForRequest(String requestId) {
    return _firestoreService.offers
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: true)
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
        .snapshots()
        .map((snapshot) {
          final offers =
              snapshot.docs
                  .map(OfferModel.fromFirestore)
                  .where(
                    (offer) =>
                        offer.providerId == providerId &&
                        (offer.chatId.isEmpty || offer.chatId == chatId),
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
  }) async {
    final request =
        await _firestoreService.serviceRequests.doc(requestId).get();
    final data = request.data();
    if (!request.exists || data == null) {
      throw const RepositoryException('La solicitud ya no existe.');
    }
    if (data['status'] != RequestStatus.open.value) {
      throw const RepositoryException('La solicitud ya no está abierta.');
    }

    final clientId = data['clientId'] as String;
    final chatId = await _chatRepository.ensureChat(
      requestId: requestId,
      clientId: clientId,
      providerId: providerId,
    );
    return createProposal(
      chatId: chatId,
      actorId: providerId,
      actorRole: 'provider',
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
  }) async {
    if (proposedPrice <= 0) {
      throw const RepositoryException('El precio debe ser mayor a cero.');
    }

    final chat = await _firestoreService.chats.doc(chatId).get();
    final chatData = chat.data();
    if (!chat.exists || chatData == null) {
      throw const RepositoryException('La conversación ya no existe.');
    }
    final clientId = chatData['clientId'] as String;
    final providerId = chatData['providerId'] as String;
    if (actorId != clientId && actorId != providerId) {
      throw const RepositoryException('No puedes crear esta propuesta.');
    }
    if (chatData['status'] != ChatStatus.active.value) {
      throw const RepositoryException('La conversación es de solo lectura.');
    }

    final requestId = chatData['requestId'] as String;
    final request =
        await _firestoreService.serviceRequests.doc(requestId).get();
    if (request.data()?['status'] != RequestStatus.open.value) {
      throw const RepositoryException('La solicitud ya no está abierta.');
    }

    final requestOffers =
        await _firestoreService.offers
            .where('requestId', isEqualTo: requestId)
            .where('providerId', isEqualTo: providerId)
            .get();
    final conversationOffers =
        requestOffers.docs.where((doc) {
          final data = doc.data();
          return data['providerId'] == providerId &&
              ((data['chatId'] as String? ?? '').isEmpty ||
                  data['chatId'] == chatId);
        }).toList();
    final previous = conversationOffers.where(
      (doc) => doc.data()['status'] == OfferStatus.pending.value,
    );
    var highestRevision = 0;
    for (final doc in conversationOffers) {
      final revision = doc.data()['revision'] as int? ?? 1;
      if (revision > highestRevision) highestRevision = revision;
    }
    final revision = highestRevision + 1;
    final supersededId = previous.isEmpty ? null : previous.first.id;
    final doc = _firestoreService.offers.doc();
    final offer = OfferModel(
      id: doc.id,
      requestId: requestId,
      providerId: providerId,
      proposedPrice: proposedPrice,
      message: conditions.trim(),
      conditions: conditions.trim(),
      status: OfferStatus.pending,
      chatId: chatId,
      createdById: actorId,
      createdByRole: actorRole,
      revision: revision,
      supersedesOfferId: supersededId,
    );

    await _firestoreService.runBatch((batch) {
      for (final oldOffer in previous) {
        batch.update(oldOffer.reference, {
          'status': OfferStatus.superseded.value,
        });
      }
      batch.set(doc, offer.toFirestore());
      batch.update(_firestoreService.chats.doc(chatId), {
        'lastMessage': 'Nueva propuesta: $proposedPrice',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    await _analyticsService.logOfferSent(requestId);
    return doc.id;
  }

  Future<void> acceptOffer({
    required OfferModel offer,
    required String actorId,
  }) async {
    if (offer.createdById == actorId) {
      throw const RepositoryException('No puedes aceptar tu propia propuesta.');
    }

    final requestRef = _firestoreService.serviceRequests.doc(offer.requestId);
    final offerRef = _firestoreService.offers.doc(offer.id);
    final requestBeforeTransaction = await requestRef.get();
    final clientId = requestBeforeTransaction.data()?['clientId'] as String?;
    if (clientId == null) {
      throw const RepositoryException('La solicitud ya no existe.');
    }
    final actorIsClient = actorId == clientId;
    final pendingOffers =
        actorIsClient
            ? await _firestoreService.offers
                .where('requestId', isEqualTo: offer.requestId)
                .where('status', isEqualTo: OfferStatus.pending.value)
                .get()
            : await _firestoreService.offers
                .where('chatId', isEqualTo: offer.chatId)
                .where('status', isEqualTo: OfferStatus.pending.value)
                .get();
    final chats =
        actorIsClient
            ? await _firestoreService.chats
                .where('requestId', isEqualTo: offer.requestId)
                .get()
            : null;

    await _firestoreService.runTransaction((transaction) async {
      final request = await transaction.get(requestRef);
      final currentOffer = await transaction.get(offerRef);
      final requestData = request.data();
      final offerData = currentOffer.data();
      if (requestData == null ||
          requestData['status'] != RequestStatus.open.value) {
        throw const RepositoryException('La solicitud ya no está abierta.');
      }
      if (offerData == null ||
          offerData['status'] != OfferStatus.pending.value) {
        throw const RepositoryException('La propuesta ya no está disponible.');
      }
      final clientId = requestData['clientId'] as String;
      final providerId = offerData['providerId'] as String;
      if (actorId != clientId && actorId != providerId) {
        throw const RepositoryException('No puedes aceptar esta propuesta.');
      }
      final creatorId =
          offerData['createdById'] as String? ??
          offerData['providerId'] as String;
      if (creatorId == actorId) {
        throw const RepositoryException(
          'No puedes aceptar tu propia propuesta.',
        );
      }

      transaction.update(offerRef, {'status': OfferStatus.accepted.value});
      for (final pending in pendingOffers.docs) {
        if (pending.id != offer.id) {
          transaction.update(pending.reference, {
            'status': OfferStatus.rejected.value,
          });
        }
      }
      transaction.update(requestRef, {
        'status': RequestStatus.accepted.value,
        'acceptedProviderId': providerId,
        'acceptedOfferId': offer.id,
        'price': offerData['proposedPrice'],
      });
      if (chats != null) {
        for (final chat in chats.docs) {
          if (chat.data()['providerId'] != providerId) {
            transaction.update(chat.reference, {
              'status': ChatStatus.readOnly.value,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    });
  }

  Future<void> rejectOffer({
    required OfferModel offer,
    required String actorId,
  }) async {
    if (offer.createdById == actorId) {
      throw const RepositoryException(
        'No puedes rechazar tu propia propuesta.',
      );
    }
    await _firestoreService.offers.doc(offer.id).update({
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
