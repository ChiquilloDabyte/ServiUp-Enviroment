import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../data/services/places_service.dart';
import '../providers/app_providers.dart';

class PlacesSearchState {
  const PlacesSearchState({
    this.suggestions = const [],
    this.isSearching = false,
    this.isSelecting = false,
    this.error,
  });

  final List<PlaceSuggestion> suggestions;
  final bool isSearching;
  final bool isSelecting;
  final String? error;

  PlacesSearchState copyWith({
    List<PlaceSuggestion>? suggestions,
    bool? isSearching,
    bool? isSelecting,
    String? error,
    bool clearError = false,
  }) {
    return PlacesSearchState(
      suggestions: suggestions ?? this.suggestions,
      isSearching: isSearching ?? this.isSearching,
      isSelecting: isSelecting ?? this.isSelecting,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PlacesSearchViewModel extends AutoDisposeNotifier<PlacesSearchState> {
  PlacesSearchViewModel({
    this.debounceDuration = const Duration(milliseconds: 350),
  });

  final Duration debounceDuration;
  Timer? _debounce;
  int _requestId = 0;
  bool _startNewSession = true;

  @override
  PlacesSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const PlacesSearchState();
  }

  void search({
    required String query,
    required double latitude,
    required double longitude,
  }) {
    _debounce?.cancel();
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 3) {
      _requestId++;
      state = const PlacesSearchState();
      return;
    }

    final requestId = ++_requestId;
    state = state.copyWith(
      suggestions: const [],
      isSearching: true,
      clearError: true,
    );
    _debounce = Timer(debounceDuration, () {
      unawaited(
        _search(
          requestId: requestId,
          query: normalizedQuery,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    });
  }

  Future<void> _search({
    required int requestId,
    required String query,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final suggestions = await ref
          .read(placesServiceProvider)
          .searchAddresses(
            query: query,
            latitude: latitude,
            longitude: longitude,
            startNewSession: _startNewSession,
          );
      if (requestId != _requestId) return;
      _startNewSession = false;
      state = state.copyWith(
        suggestions: suggestions,
        isSearching: false,
        clearError: true,
      );
    } catch (error) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        suggestions: const [],
        isSearching: false,
        error: _messageFor(error),
      );
    }
  }

  Future<PlaceSelection> selectAddress(PlaceSuggestion suggestion) async {
    _debounce?.cancel();
    _requestId++;
    state = state.copyWith(
      suggestions: const [],
      isSearching: false,
      isSelecting: true,
      clearError: true,
    );

    try {
      final selection = await ref
          .read(placesServiceProvider)
          .selectAddress(suggestion);
      _startNewSession = true;
      state = const PlacesSearchState();
      return selection;
    } catch (error) {
      state = state.copyWith(isSelecting: false, error: _messageFor(error));
      rethrow;
    }
  }

  void dismissSuggestions() {
    _debounce?.cancel();
    _requestId++;
    _startNewSession = true;
    state = const PlacesSearchState();
  }

  String _messageFor(Object error) {
    if (error is AppException) return error.message;
    return 'No se pudieron buscar direcciones.';
  }
}

final placesSearchViewModelProvider =
    AutoDisposeNotifierProvider<PlacesSearchViewModel, PlacesSearchState>(
      PlacesSearchViewModel.new,
    );
