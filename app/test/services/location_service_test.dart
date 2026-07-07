import 'package:flutter_test/flutter_test.dart';
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
}
