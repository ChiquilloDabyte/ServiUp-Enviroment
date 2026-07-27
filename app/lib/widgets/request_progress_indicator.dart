import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/enums/request_status.dart';

class RequestProgressIndicator extends StatelessWidget {
  const RequestProgressIndicator({super.key, required this.status});

  final RequestStatus status;

  double get _progress => switch (status) {
    RequestStatus.open => 0.25,
    RequestStatus.accepted => 0.5,
    RequestStatus.inProgress => 0.75,
    RequestStatus.completed || RequestStatus.cancelled => 1,
  };

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == RequestStatus.cancelled;

    return Semantics(
      label: 'Progreso del servicio: ${status.label}',
      value: '${(_progress * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: LinearProgressIndicator(
          value: _progress,
          minHeight: 4,
          color:
              isCancelled
                  ? AppColors.tertiary
                  : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
