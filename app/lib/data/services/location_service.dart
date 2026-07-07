import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/errors/app_exception.dart';
import '../../core/logger/app_logger.dart';

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
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final address = place == null
          ? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'
          : [
              place.street,
              place.locality,
              place.administrativeArea,
            ].where((part) => part != null && part.isNotEmpty).join(', ');

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

  double distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final meters = Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
    return meters / 1000;
  }
}
