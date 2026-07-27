import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';
import '../../models/enums/offer_status.dart';
import '../../models/offer_model.dart';
import '../../utils/formatters.dart';
import '../section_card.dart';

class ChatOfferPanel extends StatelessWidget {
  const ChatOfferPanel({
    super.key,
    required this.offers,
    required this.userId,
    required this.writable,
    required this.onNewProposal,
    required this.onAccept,
    required this.onReject,
  });

  final List<OfferModel> offers;
  final String userId;
  final bool writable;
  final VoidCallback onNewProposal;
  final ValueChanged<OfferModel> onAccept;
  final ValueChanged<OfferModel> onReject;

  @override
  Widget build(BuildContext context) {
    final active =
        offers
            .where((offer) => offer.status == OfferStatus.pending)
            .firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.mobileMargin,
        AppSpacing.sm,
        AppSpacing.mobileMargin,
        0,
      ),
      child: SectionCard(
        padding: EdgeInsets.zero,
        radius: AppRadius.lg,
        child: ExpansionTile(
          leading: const Icon(Icons.handshake_outlined),
          title: Text(
            active == null
                ? 'Historial de propuestas'
                : 'Propuesta: ${formatCurrency(active.proposedPrice)}',
          ),
          subtitle:
              active == null
                  ? Text('${offers.length} propuesta(s)')
                  : Text(
                    active.conditions?.isNotEmpty == true
                        ? active.conditions!
                        : 'Sin condiciones adicionales',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          trailing:
              writable
                  ? IconButton.filledTonal(
                    tooltip: 'Nueva propuesta',
                    onPressed: onNewProposal,
                    icon: const Icon(Icons.add_rounded),
                  )
                  : null,
          childrenPadding: const EdgeInsets.only(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          children: [
            if (active != null && active.createdById != userId && writable)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: AppSpacing.xs,
                  children: [
                    TextButton(
                      onPressed: () => onReject(active),
                      child: const Text('Rechazar'),
                    ),
                    FilledButton(
                      onPressed: () => onAccept(active),
                      child: const Text('Aceptar'),
                    ),
                  ],
                ),
              ),
            for (final offer in offers)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                title: Text(
                  'Versión ${offer.revision}: '
                  '${formatCurrency(offer.proposedPrice)}',
                ),
                subtitle: Text(offer.conditions ?? offer.message),
                trailing: _OfferStatusChip(status: offer.status),
              ),
          ],
        ),
      ),
    );
  }
}

class _OfferStatusChip extends StatelessWidget {
  const _OfferStatusChip({required this.status});

  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      OfferStatus.accepted => (
        colors.primaryFixed,
        colors.onPrimaryFixedVariant,
      ),
      OfferStatus.rejected => (colors.errorContainer, colors.onErrorContainer),
      OfferStatus.pending => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      OfferStatus.superseded => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(
        status.label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}
