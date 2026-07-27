import 'package:flutter/material.dart';

import '../core/theme/app_dimensions.dart';
import '../models/service_request_model.dart';
import '../utils/formatters.dart';
import 'metadata_row.dart';
import 'request_progress_indicator.dart';
import 'section_card.dart';

class RequestSummaryCard extends StatelessWidget {
  const RequestSummaryCard({super.key, required this.request});

  final ServiceRequestModel request;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      radius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.category,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Chip(label: Text(request.status.label)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          RequestProgressIndicator(status: request.status),
          const SizedBox(height: AppSpacing.gutter),
          Text(request.description),
          const SizedBox(height: AppSpacing.md),
          MetadataRow(
            icon: Icons.location_on_outlined,
            label: 'Dirección',
            value: request.address,
          ),
          const SizedBox(height: AppSpacing.gutter),
          MetadataRow(
            icon: Icons.schedule_outlined,
            label: 'Fecha y hora',
            value: formatDateTime(request.scheduledAt),
          ),
          if (request.price != null) ...[
            const SizedBox(height: AppSpacing.gutter),
            MetadataRow(
              icon: Icons.payments_outlined,
              label: 'Precio acordado',
              value: formatCurrency(request.price!),
            ),
          ],
        ],
      ),
    );
  }
}
