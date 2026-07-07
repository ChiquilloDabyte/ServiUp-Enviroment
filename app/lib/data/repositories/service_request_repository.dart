import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../models/enums/request_status.dart';
import '../../models/service_request_model.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class ServiceRequestRepository {
  ServiceRequestRepository({
    required FirestoreService firestoreService,
    required LocationService locationService,
    required AnalyticsService analyticsService,
  })  : _firestoreService = firestoreService,
        _locationService = locationService,
        _analyticsService = analyticsService;

  final FirestoreService _firestoreService;
  final LocationService _locationService;
  final AnalyticsService _analyticsService;

  Stream<List<ServiceRequestModel>> watchClientRequests(String clientId) {
    return _firestoreService.serviceRequests
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ServiceRequestModel.fromFirestore).toList(),
        );
  }

  Stream<List<ServiceRequestModel>> watchOpenRequests() {
    return _firestoreService.serviceRequests
        .where('status', isEqualTo: RequestStatus.open.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ServiceRequestModel.fromFirestore).toList(),
        );
  }

  Stream<ServiceRequestModel?> watchRequest(String requestId) {
    return _firestoreService.serviceRequests.doc(requestId).snapshots().map(
          (doc) => doc.exists ? ServiceRequestModel.fromFirestore(doc) : null,
        );
  }

  Future<List<ServiceRequestModel>> getNearbyOpenRequests({
    required double latitude,
    required double longitude,
    String? category,
    double radiusKm = AppConstants.defaultSearchRadiusKm,
  }) async {
    final snapshot = await _firestoreService.serviceRequests
        .where('status', isEqualTo: RequestStatus.open.value)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(ServiceRequestModel.fromFirestore)
        .where((request) {
          if (category != null &&
              category.isNotEmpty &&
              request.category != category) {
            return false;
          }
          final distance = _locationService.distanceKm(
            fromLat: latitude,
            fromLng: longitude,
            toLat: request.latitude,
            toLng: request.longitude,
          );
          return distance <= radiusKm;
        })
        .toList();
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
      address: address,
      scheduledAt: scheduledAt,
      status: RequestStatus.open,
      createdAt: DateTime.now(),
    );

    await doc.set(request.toFirestore());
    await _analyticsService.logRequestCreated(category);
    return doc.id;
  }

  Future<void> updateStatus({
    required String requestId,
    required RequestStatus status,
    String? acceptedProviderId,
    double? price,
  }) async {
    final updates = <String, dynamic>{'status': status.value};
    if (acceptedProviderId != null) {
      updates['acceptedProviderId'] = acceptedProviderId;
    }
    if (price != null) {
      updates['price'] = price;
    }

    await _firestoreService.serviceRequests.doc(requestId).update(updates);

    if (status == RequestStatus.completed) {
      await _analyticsService.logServiceCompleted(requestId);
    }
  }

  Future<void> cancelRequest(String requestId) {
    return updateStatus(requestId: requestId, status: RequestStatus.cancelled);
  }

  Stream<List<ServiceRequestModel>> watchProviderActiveJobs(String providerId) {
    return _firestoreService.serviceRequests
        .where('acceptedProviderId', isEqualTo: providerId)
        .where(
          'status',
          whereIn: [
            RequestStatus.accepted.value,
            RequestStatus.inProgress.value,
          ],
        )
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ServiceRequestModel.fromFirestore).toList(),
        );
  }
}
