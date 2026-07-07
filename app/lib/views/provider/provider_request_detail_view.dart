import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/offer_viewmodel.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../models/enums/request_status.dart';
import '../../utils/formatters.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/request_map_preview.dart';

class ProviderRequestDetailView extends ConsumerStatefulWidget {
  const ProviderRequestDetailView({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ProviderRequestDetailView> createState() =>
      _ProviderRequestDetailViewState();
}

class _ProviderRequestDetailViewState
    extends ConsumerState<ProviderRequestDetailView> {
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendOffer() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      setState(() => _error = 'Ingresa un precio válido.');
      return;
    }

    setState(() => _error = null);

    try {
      await ref.read(offerViewModelProvider.notifier).sendOffer(
            requestId: widget.requestId,
            providerId: user.id,
            proposedPrice: price,
            message: _messageController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oferta enviada')),
        );
      }
    } catch (e) {
      setState(() => _error = offerErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(requestDetailProvider(widget.requestId));
    final user = ref.watch(currentUserProfileProvider).value;
    final isLoading = ref.watch(offerViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del trabajo')),
      body: request.when(
        loading: () => const LoadingView(),
        error: (error, _) => Center(child: Text(repositoryErrorMessage(error))),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Solicitud no encontrada'));
          }

          final isAssignedProvider = item.acceptedProviderId == user?.id;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              Text(item.category, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(item.description),
              Text('Dirección: ${item.address}'),
              Text('Programado: ${formatDateTime(item.scheduledAt)}'),
              Text('Estado: ${item.status.label}'),
              const SizedBox(height: 16),
              RequestMapPreview(
                latitude: item.latitude,
                longitude: item.longitude,
              ),
              if (item.status == RequestStatus.open) ...[
                const SizedBox(height: 24),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Precio propuesto'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'Mensaje'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isLoading ? null : _sendOffer,
                  child: Text(isLoading ? 'Enviando...' : 'Enviar oferta'),
                ),
              ],
              if (isAssignedProvider &&
                  item.status == RequestStatus.accepted) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: user == null
                      ? null
                      : () => ref.read(offerViewModelProvider.notifier).markInProgress(
                            requestId: item.id,
                            providerId: user.id,
                          ),
                  child: const Text('Iniciar servicio'),
                ),
              ],
              if (isAssignedProvider &&
                  item.status == RequestStatus.inProgress) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: user == null
                      ? null
                      : () => ref.read(offerViewModelProvider.notifier).markCompleted(
                            requestId: item.id,
                            providerId: user.id,
                          ),
                  child: const Text('Marcar como completado'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
