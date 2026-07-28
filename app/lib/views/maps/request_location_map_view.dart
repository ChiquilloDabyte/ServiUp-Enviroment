import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../config/route_arguments.dart';
import '../../core/theme/app_dimensions.dart';
import '../../domain/providers/app_providers.dart';
import '../../widgets/deferred_until_route_transition.dart';
import '../../widgets/map_status_view.dart';

class RequestLocationMapView extends ConsumerWidget {
  const RequestLocationMapView({super.key, required this.location});

  final RequestLocationMapArgs? location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = this.location;
    if (location == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Ubicación del servicio')),
        body: const MapStatusView(message: 'La ubicación no está disponible.'),
      );
    }

    final mapsConfiguration = ref.watch(mapsConfigurationProvider);
    final position = LatLng(location.latitude, location.longitude);

    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación del servicio')),
      body: mapsConfiguration.when(
        loading:
            () => const MapStatusView(message: 'Preparando mapa completo...'),
        error:
            (_, _) => const MapStatusView(
              message:
                  'No se pudo cargar el mapa. Verifica la configuración '
                  'de Google Maps.',
            ),
        data:
            (_) => DeferredUntilRouteTransition(
              placeholder: const MapStatusView(
                message: 'Preparando mapa completo...',
              ),
              builder:
                  (_) => Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: position,
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('request'),
                            position: position,
                          ),
                        },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                      ),
                      if (location.address.isNotEmpty)
                        Positioned(
                          top: AppSpacing.gutter,
                          left: AppSpacing.gutter,
                          right: AppSpacing.gutter,
                          child: SafeArea(
                            bottom: false,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppSpacing.gutter,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(child: Text(location.address)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
            ),
      ),
    );
  }
}
