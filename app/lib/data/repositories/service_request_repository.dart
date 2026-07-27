import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logger/app_logger.dart';
import '../../models/enums/request_status.dart';
import '../../models/request_page.dart';
import '../../models/service_request_model.dart';
import '../services/analytics_service.dart';
import '../services/cloud_functions_service.dart';
import '../services/firestore_service.dart';
import 'location_repository.dart';

class ServiceRequestRepository {
  ServiceRequestRepository({
    required FirestoreService firestoreService,
    required CloudFunctionsService cloudFunctionsService,
    required LocationRepository locationRepository,
    required AnalyticsService analyticsService,
  }) : _firestoreService = firestoreService,
       _cloudFunctionsService = cloudFunctionsService,
       _locationRepository = locationRepository,
       _analyticsService = analyticsService;

  final FirestoreService _firestoreService;
  final CloudFunctionsService _cloudFunctionsService;
  final LocationRepository _locationRepository;
  final AnalyticsService _analyticsService;

  Stream<List<ServiceRequestModel>> watchClientRequests(String clientId) {
    return _firestoreService.serviceRequests
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.defaultPageSize)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ServiceRequestModel.fromFirestore).toList(),
        );
  }

  Stream<List<ServiceRequestModel>> watchOpenRequests() {
    return _firestoreService.openRequestListings
        .where('status', isEqualTo: RequestStatus.open.value)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.defaultPageSize)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ServiceRequestModel.fromFirestore).toList(),
        );
  }

  Stream<ServiceRequestModel?> watchRequest(String requestId) {
    return _firestoreService.serviceRequests
        .doc(requestId)
        .snapshots()
        .map(
          (doc) => doc.exists ? ServiceRequestModel.fromFirestore(doc) : null,
        );
  }

  Stream<ServiceRequestModel?> watchProviderRequest(String requestId) {
    return _firestoreService.openRequestListings
        .doc(requestId)
        .snapshots()
        .map(
          (doc) => doc.exists ? ServiceRequestModel.fromFirestore(doc) : null,
        );
  }

  Future<RequestPage> fetchOpenRequestPage({
    RequestPageCursor? after,
    int limit = AppConstants.defaultPageSize,
  }) async {
    Query<Map<String, dynamic>> query = _firestoreService.openRequestListings
        .where('status', isEqualTo: RequestStatus.open.value)
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (after != null) {
      query = query.startAfter([Timestamp.fromDate(after.createdAt), after.id]);
    }
    final snapshot = await query.get();
    final items = snapshot.docs.map(ServiceRequestModel.fromFirestore).toList();
    final last = items.isEmpty ? null : items.last;
    return RequestPage(
      items: items,
      nextCursor:
          items.length < limit || last?.createdAt == null
              ? null
              : RequestPageCursor(createdAt: last!.createdAt!, id: last.id),
    );
  }

  Future<List<ServiceRequestModel>> getNearbyOpenRequests({
    required double latitude,
    required double longitude,
    String? category,
    double radiusKm = AppConstants.defaultSearchRadiusKm,
  }) async {
    Query<Map<String, dynamic>> query = _firestoreService.openRequestListings
        .where('status', isEqualTo: RequestStatus.open.value)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.defaultPageSize);
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    final snapshot = await query.get();

    return snapshot.docs.map(ServiceRequestModel.fromFirestore).where((
      request,
    ) {
      final distance = _locationRepository.distanceKm(
        fromLat: latitude,
        fromLng: longitude,
        toLat: request.latitude,
        toLng: request.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  Future<String> createRequest({
    required String clientId,
    required String category,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    required DateTime scheduledAt,
  }) async {
    if (description.trim().length < 10) {
      throw const RepositoryException(
        'La descripción debe tener al menos 10 caracteres.',
      );
    }

    final doc = _firestoreService.serviceRequests.doc();
    final request = ServiceRequestModel(
      id: doc.id,
      clientId: clientId,
      category: category,
      description: description.trim(),
      latitude: latitude,
      longitude: longitude,
      address: address.trim(),
      scheduledAt: scheduledAt,
      status: RequestStatus.open,
    );
    await doc.set(request.toFirestore());
    try {
      await _analyticsService.logRequestCreated(category);
    } catch (error, stackTrace) {
      AppLogger.warning('Request analytics failed', error, stackTrace);
    }
    return doc.id;
  }

  Future<void> transition({
    required String requestId,
    required String action,
    String? reason,
  }) async {
    await _cloudFunctionsService.call('transitionServiceRequest', {
      'requestId': requestId,
      'action': action,
      if (reason != null) 'reason': reason.trim(),
    });
    if (action == 'confirm_completion') {
      try {
        await _analyticsService.logServiceCompleted(requestId);
      } catch (error, stackTrace) {
        AppLogger.warning('Completion analytics failed', error, stackTrace);
      }
    }
  }

  Future<void> cancelRequest(String requestId) {
    return transition(requestId: requestId, action: 'cancel');
  }

  Stream<List<ServiceRequestModel>> watchProviderActiveJobs(String providerId) {
    return _firestoreService.serviceRequests
        .where('acceptedProviderId', isEqualTo: providerId)
        .where(
          'status',
          whereIn: [
            RequestStatus.accepted.value,
            RequestStatus.inProgress.value,
            RequestStatus.pendingConfirmation.value,
          ],
        )
        .limit(AppConstants.defaultPageSize)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ServiceRequestModel.fromFirestore).toList(),
        );
  }
}
