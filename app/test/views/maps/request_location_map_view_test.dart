import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:serviup/config/route_arguments.dart';
import 'package:serviup/domain/providers/app_providers.dart';
import 'package:serviup/views/maps/request_location_map_view.dart';

void main() {
  testWidgets('muestra un mapa completo interactivo con la dirección', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mapsConfigurationProvider.overrideWith((ref) async {})],
        child: const MaterialApp(
          home: RequestLocationMapView(
            location: RequestLocationMapArgs(
              latitude: 4.711,
              longitude: -74.0721,
              address: 'Dirección de prueba',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(map.initialCameraPosition.target, const LatLng(4.711, -74.0721));
    expect(map.scrollGesturesEnabled, isTrue);
    expect(map.zoomGesturesEnabled, isTrue);
    expect(find.text('Dirección de prueba'), findsOneWidget);
  });
}
