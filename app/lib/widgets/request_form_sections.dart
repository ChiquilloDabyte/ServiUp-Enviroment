import 'package:flutter/material.dart';

import '../core/theme/app_dimensions.dart';
import '../data/services/places_service.dart';
import '../utils/formatters.dart';
import 'address_suggestions.dart';
import 'category_dropdown.dart';
import 'location_picker.dart';
import 'section_card.dart';

class ServiceDetailsFormSection extends StatelessWidget {
  const ServiceDetailsFormSection({
    super.key,
    required this.category,
    required this.onCategoryChanged,
    required this.descriptionController,
    required this.scheduledAt,
    required this.onPickDateTime,
  });

  final String? category;
  final ValueChanged<String?> onCategoryChanged;
  final TextEditingController descriptionController;
  final DateTime scheduledAt;
  final VoidCallback onPickDateTime;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Detalles del servicio',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.gutter),
          CategoryDropdown(value: category, onChanged: onCategoryChanged),
          const SizedBox(height: AppSpacing.gutter),
          TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripción del servicio',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
            minLines: 3,
            maxLines: 5,
            validator:
                (value) =>
                    value == null || value.length < 10
                        ? 'Describe el servicio con al menos 10 caracteres'
                        : null,
          ),
          const SizedBox(height: AppSpacing.gutter),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Fecha y hora'),
            subtitle: Text(formatDateTime(scheduledAt)),
            trailing: IconButton(
              tooltip: 'Cambiar fecha y hora',
              icon: const Icon(Icons.edit_calendar_outlined),
              onPressed: onPickDateTime,
            ),
            onTap: onPickDateTime,
          ),
        ],
      ),
    );
  }
}

class RequestLocationFormSection extends StatelessWidget {
  const RequestLocationFormSection({
    super.key,
    required this.addressController,
    required this.addressFocusNode,
    required this.suggestions,
    required this.isBusy,
    required this.coordinatesConfirmed,
    required this.latitude,
    required this.longitude,
    required this.onAddressChanged,
    required this.onAddressSubmitted,
    required this.onSuggestionSelected,
    required this.onLocationChanged,
    this.error,
  });

  final TextEditingController addressController;
  final FocusNode addressFocusNode;
  final List<PlaceSuggestion> suggestions;
  final bool isBusy;
  final bool coordinatesConfirmed;
  final double latitude;
  final double longitude;
  final ValueChanged<String> onAddressChanged;
  final VoidCallback onAddressSubmitted;
  final ValueChanged<PlaceSuggestion> onSuggestionSelected;
  final void Function(double latitude, double longitude) onLocationChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ubicación', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Busca la dirección o ajusta el punto directamente en el mapa.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          TextFormField(
            controller: addressController,
            focusNode: addressFocusNode,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.fullStreetAddress],
            decoration: InputDecoration(
              labelText: 'Dirección del servicio',
              hintText: 'Escribe una dirección',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon:
                  isBusy
                      ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : null,
            ),
            onChanged: onAddressChanged,
            onFieldSubmitted: (_) => onAddressSubmitted(),
            validator: (value) {
              if (value == null || value.trim().length < 5) {
                return 'Ingresa una dirección válida';
              }
              return null;
            },
          ),
          AddressSuggestions(
            suggestions: suggestions,
            onSelected: onSuggestionSelected,
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              error!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ] else if (!coordinatesConfirmed) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Selecciona una sugerencia o confirma el punto en el mapa.',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.gutter),
          LocationPicker(
            initialLatitude: latitude,
            initialLongitude: longitude,
            onLocationChanged: onLocationChanged,
          ),
        ],
      ),
    );
  }
}
