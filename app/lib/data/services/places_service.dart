import 'package:flutter/material.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart';

import '../../core/errors/app_exception.dart';
import '../../core/logger/app_logger.dart';
import 'maps_config_service.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullText,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String fullText;
}

class PlaceSelection {
  const PlaceSelection({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;
}

abstract interface class PlacesService {
  Future<List<PlaceSuggestion>> searchAddresses({
    required String query,
    required double latitude,
    required double longitude,
    required bool startNewSession,
  });

  Future<PlaceSelection> selectAddress(PlaceSuggestion suggestion);
}

typedef PlacesSdkFactory =
    FlutterGooglePlacesSdk Function(String apiKey, Locale locale);

class GooglePlacesService implements PlacesService {
  GooglePlacesService({
    required MapsConfigService mapsConfigService,
    PlacesSdkFactory? sdkFactory,
  }) : _mapsConfigService = mapsConfigService,
       _sdkFactory =
           sdkFactory ??
           ((apiKey, locale) => FlutterGooglePlacesSdk(apiKey, locale: locale));

  final MapsConfigService _mapsConfigService;
  final PlacesSdkFactory _sdkFactory;
  Future<FlutterGooglePlacesSdk>? _sdkFuture;

  Future<FlutterGooglePlacesSdk> _getSdk() {
    return _sdkFuture ??= _createSdk();
  }

  Future<FlutterGooglePlacesSdk> _createSdk() async {
    final apiKey = await _mapsConfigService.getApiKey();
    return _sdkFactory(apiKey, const Locale('es', 'CO'));
  }

  @override
  Future<List<PlaceSuggestion>> searchAddresses({
    required String query,
    required double latitude,
    required double longitude,
    required bool startNewSession,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 3) return const [];

    try {
      final sdk = await _getSdk();
      final response = await sdk.findAutocompletePredictions(
        normalizedQuery,
        countries: const ['CO'],
        newSessionToken: startNewSession,
        origin: LatLng(lat: latitude, lng: longitude),
        locationBias: _locationBias(latitude, longitude),
      );

      return response.predictions
          .where((prediction) => prediction.placeId?.isNotEmpty == true)
          .map((prediction) {
            final fullText = prediction.fullText?.trim() ?? '';
            final primaryText = prediction.primaryText?.trim();
            return PlaceSuggestion(
              placeId: prediction.placeId!,
              primaryText:
                  primaryText?.isNotEmpty == true ? primaryText! : fullText,
              secondaryText: prediction.secondaryText?.trim() ?? '',
              fullText: fullText,
            );
          })
          .toList(growable: false);
    } catch (error, stackTrace) {
      AppLogger.error('Places autocomplete failed', error, stackTrace);
      throw const RepositoryException(
        'No se pudieron cargar sugerencias de direcciones.',
      );
    }
  }

  @override
  Future<PlaceSelection> selectAddress(PlaceSuggestion suggestion) async {
    try {
      final sdk = await _getSdk();
      final response = await sdk.fetchPlace(
        suggestion.placeId,
        fields: const [
          PlaceField.Id,
          PlaceField.Location,
          PlaceField.FormattedAddress,
        ],
        newSessionToken: false,
      );
      final place = response.place;
      final location = place?.latLng;
      if (location == null) {
        throw const RepositoryException(
          'Google Places no devolvió las coordenadas de la dirección.',
        );
      }

      return PlaceSelection(
        address:
            place?.address?.trim().isNotEmpty == true
                ? place!.address!.trim()
                : suggestion.fullText,
        latitude: location.lat,
        longitude: location.lng,
      );
    } catch (error, stackTrace) {
      if (error is RepositoryException) rethrow;
      AppLogger.error('Place details lookup failed', error, stackTrace);
      throw const RepositoryException('No se pudo seleccionar esta dirección.');
    }
  }

  LatLngBounds _locationBias(double latitude, double longitude) {
    const latitudeDelta = 0.45;
    const longitudeDelta = 0.45;
    return LatLngBounds(
      southwest: LatLng(
        lat: latitude - latitudeDelta,
        lng: longitude - longitudeDelta,
      ),
      northeast: LatLng(
        lat: latitude + latitudeDelta,
        lng: longitude + longitudeDelta,
      ),
    );
  }
}
