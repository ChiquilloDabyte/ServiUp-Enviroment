import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/enums/offer_status.dart';

class OfferStatusChip extends StatelessWidget {
  const OfferStatusChip({super.key, required this.status});

  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      OfferStatus.pending => (
        AppColors.secondaryFixed,
        AppColors.onSecondaryFixedVariant,
      ),
      OfferStatus.accepted => (
        AppColors.primaryFixed,
        AppColors.onPrimaryFixedVariant,
      ),
      OfferStatus.rejected => (
        AppColors.tertiaryFixed,
        AppColors.onTertiaryFixedVariant,
      ),
      OfferStatus.superseded => (
        AppColors.surfaceContainerHighest,
        AppColors.onSurfaceVariant,
      ),
    };

    return Chip(
      backgroundColor: background,
      label: Text(status.label, style: TextStyle(color: foreground)),
      avatar: Icon(Icons.circle, size: 8, color: foreground),
    );
  }
}
