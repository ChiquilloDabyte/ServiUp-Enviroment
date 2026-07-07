import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../models/service_request_model.dart';
import '../providers/app_providers.dart';

class ServiceRequestViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String> createRequest({
    required String clientId,
    required String category,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    required DateTime scheduledAt,
  }) async {
    state = const AsyncLoading();
    late String requestId;

    state = await AsyncValue.guard(() async {
      requestId = await ref.read(serviceRequestRepositoryProvider).createRequest(
            clientId: clientId,
            category: category,
            description: description,
            latitude: latitude,
            longitude: longitude,
            address: address,
            scheduledAt: scheduledAt,
          );
    });

    if (state.hasError) throw state.error!;
    return requestId;
  }

  Future<void> cancelRequest(String requestId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(serviceRequestRepositoryProvider)
          .cancelRequest(requestId);
    });
    if (state.hasError) throw state.error!;
  }
}

final serviceRequestViewModelProvider =
    NotifierProvider<ServiceRequestViewModel, AsyncValue<void>>(
  ServiceRequestViewModel.new,
);

final clientRequestsProvider =
    StreamProvider.family<List<ServiceRequestModel>, String>((ref, clientId) {
  return ref
      .watch(serviceRequestRepositoryProvider)
      .watchClientRequests(clientId);
});

final openRequestsProvider = StreamProvider<List<ServiceRequestModel>>((ref) {
  return ref.watch(serviceRequestRepositoryProvider).watchOpenRequests();
});

final requestDetailProvider =
    StreamProvider.family<ServiceRequestModel?, String>((ref, requestId) {
  return ref.watch(serviceRequestRepositoryProvider).watchRequest(requestId);
});

final nearbyRequestsProvider = FutureProvider.family<
    List<ServiceRequestModel>,
    ({double lat, double lng, String? category})>((ref, params) {
  return ref.read(serviceRequestRepositoryProvider).getNearbyOpenRequests(
        latitude: params.lat,
        longitude: params.lng,
        category: params.category,
      );
});

final providerActiveJobsProvider =
    StreamProvider.family<List<ServiceRequestModel>, String>((ref, providerId) {
  return ref
      .watch(serviceRequestRepositoryProvider)
      .watchProviderActiveJobs(providerId);
});

String repositoryErrorMessage(Object error) {
  if (error is AppException) return error.message;
  return 'No se pudo completar la operación.';
}
