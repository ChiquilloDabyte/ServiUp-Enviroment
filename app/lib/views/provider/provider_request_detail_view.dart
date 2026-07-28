import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/route_arguments.dart';
import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/offer_viewmodel.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../models/enums/request_status.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/request_map_preview.dart';
import '../../widgets/request_summary_card.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

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
      await ref
          .read(offerViewModelProvider.notifier)
          .sendOffer(
            requestId: widget.requestId,
            providerId: user.id,
            proposedPrice: price,
            message: _messageController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Oferta enviada')));
        context.push('/chats/${widget.requestId}_${user.id}');
      }
    } catch (e) {
      setState(() => _error = offerErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(providerRequestDetailProvider(widget.requestId));
    final user = ref.watch(currentUserProfileProvider).value;
    final isLoading = ref.watch(offerViewModelProvider).isLoading;
    final providerOffers =
        user == null
            ? const AsyncValue<List<dynamic>>.loading()
            : ref.watch(providerOffersProvider(user.id));

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

          return ResponsiveContent(
            maxWidth: 900,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpacing.md),
                ],
                RequestSummaryCard(request: item),
                const SizedBox(height: AppSpacing.md),
                RequestMapPreview(
                  latitude: item.latitude,
                  longitude: item.longitude,
                  onOpenMap:
                      () => context.push(
                        '/request-location',
                        extra: RequestLocationMapArgs(
                          latitude: item.latitude,
                          longitude: item.longitude,
                          address: item.address,
                        ),
                      ),
                ),
                if (item.status == RequestStatus.open) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Envía tu propuesta',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Indica un precio y agrega un mensaje para el cliente.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.gutter),
                        TextField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Precio propuesto',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            labelText: 'Mensaje',
                            prefixIcon: Icon(Icons.message_outlined),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.gutter),
                        FilledButton.icon(
                          onPressed: isLoading ? null : _sendOffer,
                          icon: const Icon(Icons.send_outlined),
                          label: Text(
                            isLoading ? 'Enviando...' : 'Enviar oferta',
                          ),
                        ),
                      ],
                    ),
                  ),
                  providerOffers.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (offers) {
                      final hasOffer = offers.any(
                        (offer) => offer.requestId == item.id,
                      );
                      if (!hasOffer || user == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: OutlinedButton.icon(
                          onPressed:
                              () =>
                                  context.push('/chats/${item.id}_${user.id}'),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Conversar'),
                        ),
                      );
                    },
                  ),
                ],
                if (isAssignedProvider &&
                    item.status == RequestStatus.accepted) ...[
                  const SizedBox(height: AppSpacing.gutter),
                  FilledButton.icon(
                    onPressed:
                        user == null
                            ? null
                            : () => ref
                                .read(offerViewModelProvider.notifier)
                                .markInProgress(
                                  requestId: item.id,
                                  providerId: user.id,
                                ),
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: const Text('Iniciar servicio'),
                  ),
                ],
                if (isAssignedProvider &&
                    item.status == RequestStatus.inProgress) ...[
                  const SizedBox(height: AppSpacing.gutter),
                  FilledButton.icon(
                    onPressed:
                        user == null
                            ? null
                            : () => ref
                                .read(offerViewModelProvider.notifier)
                                .requestCompletion(
                                  requestId: item.id,
                                  providerId: user.id,
                                ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Solicitar confirmación'),
                  ),
                ],
                if (isAssignedProvider &&
                    item.status == RequestStatus.pendingConfirmation) ...[
                  const SizedBox(height: AppSpacing.gutter),
                  const SectionCard(
                    child: Text(
                      'El cliente debe confirmar la finalización. '
                      'Puedes seguir usando el chat mientras responde.',
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
