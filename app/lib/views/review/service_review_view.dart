import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/review_viewmodel.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../models/enums/request_status.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/section_card.dart';

class ServiceReviewView extends ConsumerWidget {
  const ServiceReviewView({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(requestDetailProvider(requestId));
    final review = ref.watch(reviewDetailProvider(requestId));
    final user = ref.watch(currentUserProfileProvider).value;
    final saving = ref.watch(reviewViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Calificar servicio')),
      body: request.when(
        loading: () => const LoadingView(),
        error: (error, _) => Center(child: Text(repositoryErrorMessage(error))),
        data: (item) {
          if (item == null) {
            return const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'Solicitud no encontrada',
            );
          }
          if (user == null ||
              user.id != item.clientId ||
              item.status != RequestStatus.completed ||
              item.acceptedProviderId == null) {
            return const EmptyState(
              icon: Icons.star_outline,
              title: 'Este servicio no se puede calificar',
              message:
                  'Solo el cliente puede calificar un servicio completado.',
            );
          }

          return review.when(
            loading: () => const LoadingView(),
            error: (error, _) => Center(child: Text(reviewErrorMessage(error))),
            data: (existing) {
              if (existing != null) {
                return ResponsiveContent(
                  maxWidth: 640,
                  child: EmptyState(
                    icon: Icons.verified_outlined,
                    title: 'Ya calificaste este servicio',
                    message:
                        'Tu calificación fue de ${existing.rating} estrellas.',
                    action: FilledButton(
                      onPressed: context.pop,
                      child: const Text('Volver al servicio'),
                    ),
                  ),
                );
              }

              return ResponsiveContent(
                maxWidth: 640,
                child: ServiceReviewForm(
                  saving: saving,
                  onSubmit: (rating, comment) async {
                    try {
                      await ref
                          .read(reviewViewModelProvider.notifier)
                          .createReview(
                            request: item,
                            clientId: user.id,
                            rating: rating,
                            comment: comment,
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Gracias por tu calificación!'),
                        ),
                      );
                      context.pop();
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(reviewErrorMessage(error))),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ServiceReviewForm extends StatefulWidget {
  const ServiceReviewForm({
    super.key,
    required this.saving,
    required this.onSubmit,
  });

  final bool saving;
  final Future<void> Function(int rating, String comment) onSubmit;

  @override
  State<ServiceReviewForm> createState() => _ServiceReviewFormState();
}

class _ServiceReviewFormState extends State<ServiceReviewForm> {
  final _commentController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _ratingLabel => switch (_rating) {
    1 => 'Muy malo',
    2 => 'Malo',
    3 => 'Regular',
    4 => 'Bueno',
    5 => 'Excelente',
    _ => 'Selecciona una calificación',
  };

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una calificación antes de continuar.'),
        ),
      );
      return;
    }
    await widget.onSubmit(_rating, _commentController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const Icon(Icons.verified_outlined, size: 64),
        const SizedBox(height: AppSpacing.gutter),
        Text(
          'Servicio completado',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Tu opinión ayuda a otros clientes a elegir un prestador.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: 'Calificación de $_rating de 5 estrellas',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      tooltip: '$value estrellas',
                      onPressed:
                          widget.saving
                              ? null
                              : () => setState(() => _rating = value),
                      icon: Icon(
                        value <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 34,
                      ),
                    );
                  }),
                ),
              ),
              Text(
                _ratingLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _commentController,
                enabled: !widget.saving,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  hintText: 'Cuéntanos cómo fue tu experiencia.',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: widget.saving ? null : _submit,
          icon:
              widget.saving
                  ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.send_outlined),
          label: Text(widget.saving ? 'Enviando...' : 'Enviar calificación'),
        ),
      ],
    );
  }
}
