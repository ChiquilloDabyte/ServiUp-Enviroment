import 'package:geocoding/geocoding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/errors/app_exception.dart';
import 'package:serviup/data/services/location_service.dart';

void main() {
  test('distanceKm calculates approximate distance', () {
    final service = LocationService();
    final distance = service.distanceKm(
      fromLat: 4.7110,
      fromLng: -74.0721,
      toLat: 4.7200,
      toLng: -74.0800,
    );

    expect(distance, greaterThan(0));
    expect(distance, lessThan(5));
  });

  test('getAddressFromCoordinates formats the resolved placemark', () async {
    final service = LocationService(
      placemarkLookup:
          (latitude, longitude) async => const [
            Placemark(
              street: 'Carrera 7 # 72-41',
              locality: 'Bogotá',
              administrativeArea: 'Bogotá D.C.',
            ),
          ],
    );

    final address = await service.getAddressFromCoordinates(
      latitude: 4.6564,
      longitude: -74.0552,
    );

    expect(address, 'Carrera 7 # 72-41, Bogotá, Bogotá D.C.');
  });

  test('getAddressFromCoordinates falls back to coordinates', () async {
    final service = LocationService(
      placemarkLookup: (latitude, longitude) async => const [],
    );

    final address = await service.getAddressFromCoordinates(
      latitude: 4.6564,
      longitude: -74.0552,
    );

    expect(address, '4.6564, -74.0552');
  });

  test('getAddressFromCoordinates handles geocoding failures', () async {
    final service = LocationService(
      placemarkLookup: (latitude, longitude) async {
        throw Exception('Geocoding unavailable');
      },
    );

    final address = await service.getAddressFromCoordinates(
      latitude: 4.6564,
      longitude: -74.0552,
    );

    expect(address, '4.6564, -74.0552');
  });

  test('getAddressFromCoordinates ignores duplicate address parts', () async {
    final service = LocationService(
      placemarkLookup:
          (latitude, longitude) async => const [
            Placemark(
              street: 'Bogotá',
              locality: 'Bogotá',
              administrativeArea: 'Cundinamarca',
            ),
          ],
    );

    final address = await service.getAddressFromCoordinates(
      latitude: 4.711,
      longitude: -74.0721,
    );

    expect(address, 'Bogotá, Cundinamarca');
  });

  test(
    'getLocationFromAddress returns coordinates for typed address',
    () async {
      final service = LocationService(
        addressLookup:
            (address) async => [
              Location(
                latitude: 4.6564,
                longitude: -74.0552,
                timestamp: DateTime.utc(2026),
              ),
            ],
      );

      final location = await service.getLocationFromAddress(
        '  Carrera 7 # 72-41, Bogotá  ',
      );

      expect(location.address, 'Carrera 7 # 72-41, Bogotá');
      expect(location.latitude, 4.6564);
      expect(location.longitude, -74.0552);
    },
  );

  test('getLocationFromAddress rejects unresolved address', () async {
    final service = LocationService(addressLookup: (address) async => []);

    expect(
      () => service.getLocationFromAddress('Dirección inexistente'),
      throwsA(isA<RepositoryException>()),
    );
  });
}
