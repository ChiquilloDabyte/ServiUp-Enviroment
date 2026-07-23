import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/errors/app_exception.dart';
import '../../core/logger/app_logger.dart';

typedef PlacemarkLookup =
    Future<List<Placemark>> Function(double latitude, double longitude);
typedef AddressLookup = Future<List<Location>> Function(String address);

class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}

class LocationService {
  LocationService({
    PlacemarkLookup placemarkLookup = placemarkFromCoordinates,
    AddressLookup addressLookup = locationFromAddress,
  }) : _placemarkLookup = placemarkLookup,
       _addressLookup = addressLookup;

  final PlacemarkLookup _placemarkLookup;
  final AddressLookup _addressLookup;

  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<LocationData> getCurrentLocation() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) {
      throw const RepositoryException('Permiso de ubicación denegado.');
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final address = await getAddressFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to get location', e, stack);
      throw const RepositoryException('No se pudo obtener la ubicación.');
    }
  }

  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final fallback = _formatCoordinates(latitude, longitude);

    try {
      final placemarks = await _placemarkLookup(latitude, longitude);
      if (placemarks.isEmpty) return fallback;

      final address = _formatPlacemark(placemarks.first);
      return address.isEmpty ? fallback : address;
    } catch (e, stack) {
      AppLogger.error('Failed to resolve address', e, stack);
      return fallback;
    }
  }

  Future<LocationData> getLocationFromAddress(String address) async {
    final normalizedAddress = address.trim();
    if (normalizedAddress.length < 5) {
      throw const RepositoryException('Ingresa una dirección válida.');
    }

    try {
      final locations = await _addressLookup(normalizedAddress);
      if (locations.isEmpty) {
        throw const RepositoryException(
          'No se encontraron coordenadas para esta dirección.',
        );
      }

      final location = locations.first;
      return LocationData(
        latitude: location.latitude,
        longitude: location.longitude,
        address: normalizedAddress,
      );
    } catch (error, stackTrace) {
      if (error is RepositoryException) rethrow;
      AppLogger.error('Failed to resolve typed address', error, stackTrace);
      throw const RepositoryException(
        'Selecciona una sugerencia o marca el punto en el mapa.',
      );
    }
  }

  double distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final meters = Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
    return meters / 1000;
  }

  String _formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  String _formatPlacemark(Placemark placemark) {
    return [placemark.street, placemark.locality, placemark.administrativeArea]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) {
          return part.isNotEmpty;
        })
        .toSet()
        .join(', ');
  }
}
