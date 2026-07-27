import '../services/location_service.dart';

class LocationRepository {
  LocationRepository({required LocationService locationService})
    : _locationService = locationService;

  final LocationService _locationService;

  Future<LocationData> getCurrentLocation() {
    return _locationService.getCurrentLocation();
  }

  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) {
    return _locationService.getAddressFromCoordinates(
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<LocationData> getLocationFromAddress(String address) {
    return _locationService.getLocationFromAddress(address);
  }

  double distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return _locationService.distanceKm(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
  }
}
