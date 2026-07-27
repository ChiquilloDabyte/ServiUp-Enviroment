import 'package:flutter/material.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart';

import '../data/services/places_service.dart';

class AddressSuggestions extends StatelessWidget {
  const AddressSuggestions({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<PlaceSuggestion> suggestions;
  final ValueChanged<PlaceSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(top: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(suggestion.primaryText),
                  subtitle:
                      suggestion.secondaryText.isEmpty
                          ? null
                          : Text(suggestion.secondaryText),
                  onTap: () => onSelected(suggestion),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Image(
                image: FlutterGooglePlacesSdk.assetPoweredByGoogleOnWhite,
                height: 14,
                semanticLabel: 'Powered by Google',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
