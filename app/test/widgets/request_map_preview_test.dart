import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:serviup/data/services/maps_config_service.dart';
import 'package:serviup/domain/providers/app_providers.dart';
import 'package:serviup/widgets/request_map_preview.dart';

void main() {
  testWidgets(
    'crea el mapa en la ubicación de la solicitud al estar configurado',
    (tester) async {
      var openedMap = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mapsConfigurationProvider.overrideWith((ref) async {})],
          child: MaterialApp(
            home: Scaffold(
              body: RequestMapPreview(
                latitude: 4.711,
                longitude: -74.0721,
                onOpenMap: () => openedMap = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.initialCameraPosition.target, const LatLng(4.711, -74.0721));
      expect(map.markers.single.position, const LatLng(4.711, -74.0721));
      expect(map.liteModeEnabled, isTrue);
      expect(map.scrollGesturesEnabled, isFalse);
      expect(map.zoomGesturesEnabled, isFalse);

      await tester.tapAt(tester.getCenter(find.byType(RequestMapPreview)));
      expect(openedMap, isTrue);
    },
  );

  testWidgets(
    'muestra un estado explícito cuando Google Maps no está configurado',
    (tester) async {
      final mapsConfigService = MapsConfigService(
        apiKeyLookup: () async => null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mapsConfigServiceProvider.overrideWithValue(mapsConfigService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RequestMapPreview(
                latitude: 4.711,
                longitude: -74.0721,
                onOpenMap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No se pudo cargar el mapa. Verifica la configuración de Google Maps.',
        ),
        findsOneWidget,
      );
      expect(find.byType(GoogleMap), findsNothing);
    },
  );
}
