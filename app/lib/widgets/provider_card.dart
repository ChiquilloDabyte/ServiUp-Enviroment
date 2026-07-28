import 'package:flutter/material.dart';

import '../core/theme/app_dimensions.dart';
import '../models/provider_public_profile_model.dart';
import 'section_card.dart';

class ProviderCard extends StatelessWidget {
  const ProviderCard({super.key, required this.provider, this.onTap});

  final ProviderPublicProfileModel provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: onTap != null,
      label: 'Prestador ${provider.name}',
      child: InkWell(
        borderRadius: AppRadius.serviceCard,
        onTap: onTap,
        child: SectionCard(
          radius: AppRadius.xl,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                foregroundImage:
                    provider.photoUrl == null
                        ? null
                        : NetworkImage(provider.photoUrl!),
                child:
                    provider.photoUrl == null
                        ? const Icon(Icons.person_outline)
                        : null,
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.name, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    if (provider.serviceCategories.isEmpty)
                      Text(
                        'Sin categorías registradas',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        children:
                            provider.serviceCategories
                                .map((category) => Chip(label: Text(category)))
                                .toList(),
                      ),
                  ],
                ),
              ),
              if (provider.ratingCount > 0) ...[
                const SizedBox(width: AppSpacing.xs),
                Semantics(
                  label:
                      'Calificación ${provider.rating.toStringAsFixed(1)} '
                      'de 5, ${provider.ratingCount} reseñas',
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(provider.rating.toStringAsFixed(1)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
