import 'package:flutter/material.dart';

import '../models/enums/request_status.dart';
import '../models/service_request_model.dart';

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
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(request.category),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(request.address),
            Text('Estado: ${request.status.label}'),
          ],
        ),
        trailing: trailing,
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(status.label));
  }
}
