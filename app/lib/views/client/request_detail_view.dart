import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/offer_viewmodel.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../models/enums/offer_status.dart';
import '../../models/enums/request_status.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/request_map_preview.dart';

class ClientRequestDetailView extends ConsumerWidget {
  const ClientRequestDetailView({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(requestDetailProvider(requestId));
    final offers = ref.watch(requestOffersProvider(requestId));
    final user = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de solicitud')),
      body: request.when(
        loading: () => const LoadingView(),
        error: (error, _) => Center(child: Text(repositoryErrorMessage(error))),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Solicitud no encontrada'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(item.category, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(item.description),
              const SizedBox(height: 8),
              Text('Dirección: ${item.address}'),
              Text('Programado: ${formatDateTime(item.scheduledAt)}'),
              Text('Estado: ${item.status.label}'),
              if (item.price != null) Text('Precio: ${formatCurrency(item.price!)}'),
              const SizedBox(height: 16),
              RequestMapPreview(
                latitude: item.latitude,
                longitude: item.longitude,
              ),
              if (item.status == RequestStatus.open) ...[
                const SizedBox(height: 24),
                Text('Ofertas recibidas', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                offers.when(
                  loading: () => const LoadingView(),
                  error: (error, _) => Text(offerErrorMessage(error)),
                  data: (offerList) {
                    if (offerList.isEmpty) {
                      return const Text('Aún no hay ofertas.');
                    }

                    return Column(
                      children: offerList.map((offer) {
                        return Card(
                          child: ListTile(
                            title: Text(formatCurrency(offer.proposedPrice)),
                            subtitle: Text(offer.message),
                            trailing: offer.status == OfferStatus.pending
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle),
                                        onPressed: user == null
                                            ? null
                                            : () async {
                                                await ref
                                                    .read(offerViewModelProvider.notifier)
                                                    .acceptOffer(
                                                      offer: offer,
                                                      clientId: user.id,
                                                    );
                                              },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel),
                                        onPressed: () => ref
                                            .read(offerViewModelProvider.notifier)
                                            .rejectOffer(offer.id),
                                      ),
                                    ],
                                  )
                                : Text(offer.status.label),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
              if (item.status == RequestStatus.open)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(serviceRequestViewModelProvider.notifier)
                        .cancelRequest(item.id),
                    child: const Text('Cancelar solicitud'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
