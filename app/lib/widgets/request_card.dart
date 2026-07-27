import 'package:flutter/material.dart';

import '../core/theme/app_dimensions.dart';
import '../models/enums/request_status.dart';
import '../models/service_request_model.dart';
import 'metadata_row.dart';
import 'section_card.dart';

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.trailing,
  });

  final ServiceRequestModel request;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: onTap != null,
      child: InkWell(
        borderRadius: AppRadius.serviceCard,
        onTap: onTap,
        child: SectionCard(
          radius: AppRadius.xl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(request.category, style: textTheme.titleLarge),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusChip(status: request.status),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.gutter),
              MetadataRow(
                icon: Icons.location_on_outlined,
                label: 'Dirección',
                value: request.address,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      RequestStatus.open => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      RequestStatus.accepted => (
        colors.primaryFixed,
        colors.onPrimaryFixedVariant,
      ),
      RequestStatus.inProgress => (
        colors.primaryContainer.withValues(alpha: 0.12),
        colors.primary,
      ),
      RequestStatus.completed => (
        colors.primary.withValues(alpha: 0.10),
        colors.primary,
      ),
      RequestStatus.cancelled => (
        colors.errorContainer,
        colors.onErrorContainer,
      ),
    };

    return Semantics(
      label: 'Estado de la solicitud: ${status.label}',
      child: ExcludeSemantics(
        child: Chip(
          label: Text(status.label),
          backgroundColor: background,
          labelStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: foreground),
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
