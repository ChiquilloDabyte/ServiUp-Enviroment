import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/data/services/places_service.dart';
import 'package:serviup/domain/providers/app_providers.dart';
import 'package:serviup/domain/viewmodels/places_search_viewmodel.dart';

class FakePlacesService implements PlacesService {
  final suggestions = const [
    PlaceSuggestion(
      placeId: 'place-id',
      primaryText: 'Carrera 7 # 72-41',
      secondaryText: 'Bogotá, Colombia',
      fullText: 'Carrera 7 # 72-41, Bogotá, Colombia',
    ),
  ];

  String? lastQuery;
  bool? lastStartNewSession;

  @override
  Future<List<PlaceSuggestion>> searchAddresses({
    required String query,
    required double latitude,
    required double longitude,
    required bool startNewSession,
  }) async {
    lastQuery = query;
    lastStartNewSession = startNewSession;
    return suggestions;
  }

  @override
  Future<PlaceSelection> selectAddress(PlaceSuggestion suggestion) async {
    return const PlaceSelection(
      address: 'Carrera 7 # 72-41, Bogotá, Colombia',
      latitude: 4.6564,
      longitude: -74.0552,
    );
  }
}

void main() {
  test('search debounces query and exposes Places suggestions', () async {
    final service = FakePlacesService();
    final container = ProviderContainer(
      overrides: [
        placesServiceProvider.overrideWithValue(service),
        placesSearchViewModelProvider.overrideWith(
          () => PlacesSearchViewModel(debounceDuration: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      placesSearchViewModelProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    container
        .read(placesSearchViewModelProvider.notifier)
        .search(query: 'Carrera 7', latitude: 4.711, longitude: -74.0721);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = container.read(placesSearchViewModelProvider);
    expect(service.lastQuery, 'Carrera 7');
    expect(service.lastStartNewSession, isTrue);
    expect(state.isSearching, isFalse);
    expect(state.suggestions, service.suggestions);
  });

  test('selectAddress returns coordinates and clears suggestions', () async {
    final service = FakePlacesService();
    final container = ProviderContainer(
      overrides: [placesServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      placesSearchViewModelProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final selection = await container
        .read(placesSearchViewModelProvider.notifier)
        .selectAddress(service.suggestions.first);

    expect(selection.latitude, 4.6564);
    expect(selection.longitude, -74.0552);
    expect(
      container.read(placesSearchViewModelProvider),
      isA<PlacesSearchState>()
          .having((state) => state.isSelecting, 'isSelecting', isFalse)
          .having((state) => state.suggestions, 'suggestions', isEmpty),
    );
  });
}
