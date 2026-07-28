import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/route_arguments.dart';
import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/chat_viewmodel.dart';
import '../../domain/viewmodels/offer_viewmodel.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../models/enums/offer_status.dart';
import '../../models/enums/request_status.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/offer_status_chip.dart';
import '../../widgets/request_map_preview.dart';
import '../../widgets/request_summary_card.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class ClientRequestDetailView extends ConsumerWidget {
  const ClientRequestDetailView({super.key, required this.requestId});

  final String requestId;

  Future<void> _returnToProgress(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Devolver al prestador'),
            content: TextField(
              controller: controller,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                helperText: 'Describe qué falta por completar.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.length >= 10) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
                child: const Text('Devolver'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (reason == null || !context.mounted) return;
    try {
      await ref
          .read(offerViewModelProvider.notifier)
          .returnToProgress(requestId: requestId, reason: reason);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(offerErrorMessage(error))));
    }
  }

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

          return ResponsiveContent(
            maxWidth: 900,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
                if (item.status == RequestStatus.pendingConfirmation &&
                    user?.id == item.clientId) ...[
                  const SizedBox(height: AppSpacing.md),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Confirma el servicio',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'El prestador indicó que terminó. Confirma si el '
                          'trabajo quedó listo o explica qué falta.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed:
                              () => ref
                                  .read(offerViewModelProvider.notifier)
                                  .confirmCompletion(requestId: item.id),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Confirmar finalización'),
                        ),
                        TextButton(
                          onPressed: () => _returnToProgress(context, ref),
                          child: const Text('Todavía falta trabajo'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (item.completionReturnReason?.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.md),
                  SectionCard(
                    child: Text(
                      'Último motivo de devolución: '
                      '${item.completionReturnReason}',
                    ),
                  ),
                ],
                if (item.status != RequestStatus.cancelled) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Ofertas recibidas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  offers.when(
                    loading: () => const LoadingView(),
                    error: (error, _) => Text(offerErrorMessage(error)),
                    data: (offerList) {
                      if (offerList.isEmpty) {
                        return const Text('Aún no hay ofertas.');
                      }

                      return Column(
                        children:
                            offerList.map((offer) {
                              final canDecide =
                                  offer.status == OfferStatus.pending &&
                                  user != null &&
                                  offer.createdById != user.id;
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: SectionCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              formatCurrency(
                                                offer.proposedPrice,
                                              ),
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
                                            ),
                                          ),
                                          OfferStatusChip(status: offer.status),
                                        ],
                                      ),
                                      if (offer.message.isNotEmpty)
                                        Text(offer.message),
                                      const SizedBox(height: AppSpacing.sm),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed:
                                                user == null
                                                    ? null
                                                    : () async {
                                                      final chatId =
                                                          offer.chatId.isEmpty
                                                              ? await ref
                                                                  .read(
                                                                    chatViewModelProvider
                                                                        .notifier,
                                                                  )
                                                                  .ensureChat(
                                                                    requestId:
                                                                        item.id,
                                                                    clientId:
                                                                        item.clientId,
                                                                    providerId:
                                                                        offer
                                                                            .providerId,
                                                                  )
                                                              : offer.chatId;
                                                      if (context.mounted) {
                                                        context.push(
                                                          '/chats/$chatId',
                                                        );
                                                      }
                                                    },
                                            icon: const Icon(
                                              Icons.chat_bubble_outline,
                                            ),
                                            label: const Text('Conversar'),
                                          ),
                                          if (canDecide)
                                            FilledButton(
                                              onPressed:
                                                  () => ref
                                                      .read(
                                                        offerViewModelProvider
                                                            .notifier,
                                                      )
                                                      .acceptOffer(
                                                        offer: offer,
                                                        actorId: user.id,
                                                      ),
                                              child: const Text('Aceptar'),
                                            ),
                                          if (canDecide)
                                            TextButton(
                                              onPressed:
                                                  () => ref
                                                      .read(
                                                        offerViewModelProvider
                                                            .notifier,
                                                      )
                                                      .rejectOffer(
                                                        offer: offer,
                                                        actorId: user.id,
                                                      ),
                                              child: const Text('Rechazar'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      );
                    },
                  ),
                ],
                if (item.status == RequestStatus.open)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.gutter),
                    child: OutlinedButton.icon(
                      onPressed:
                          () => ref
                              .read(serviceRequestViewModelProvider.notifier)
                              .cancelRequest(item.id),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar solicitud'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
