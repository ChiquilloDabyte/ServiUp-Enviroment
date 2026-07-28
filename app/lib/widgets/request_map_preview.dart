import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/theme/app_dimensions.dart';
import '../domain/providers/app_providers.dart';
import 'deferred_until_route_transition.dart';
import 'map_status_view.dart';

class RequestMapPreview extends ConsumerWidget {
  const RequestMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onOpenMap,
  });

  final double latitude;
  final double longitude;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = LatLng(latitude, longitude);
    final colors = Theme.of(context).colorScheme;
    final mapsConfiguration = ref.watch(mapsConfigurationProvider);

    return Semantics(
      label: 'Mapa de la ubicación del servicio',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.serviceCard,
          border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.serviceCard,
          child: SizedBox(
            height: 200,
            child: mapsConfiguration.when(
              loading: () => const MapStatusView(message: 'Preparando mapa...'),
              error:
                  (_, _) => const MapStatusView(
                    message:
                        'No se pudo cargar el mapa. Verifica la configuración '
                        'de Google Maps.',
                  ),
              data:
                  (_) => DeferredUntilRouteTransition(
                    placeholder: const MapStatusView(
                      message: 'Preparando mapa...',
                    ),
                    builder:
                        (_) => Semantics(
                          button: true,
                          label: 'Abrir mapa completo de la ubicación',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onOpenMap,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                IgnorePointer(
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: position,
                                      zoom: 15,
                                    ),
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId('request'),
                                        position: position,
                                      ),
                                    },
                                    liteModeEnabled: true,
                                    zoomControlsEnabled: false,
                                    myLocationButtonEnabled: false,
                                    compassEnabled: false,
                                    mapToolbarEnabled: false,
                                    rotateGesturesEnabled: false,
                                    scrollGesturesEnabled: false,
                                    tiltGesturesEnabled: false,
                                    zoomGesturesEnabled: false,
                                  ),
                                ),
                                Positioned(
                                  right: AppSpacing.sm,
                                  bottom: AppSpacing.sm,
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: colors.surface.withValues(
                                          alpha: 0.92,
                                        ),
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(AppRadius.xl),
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            blurRadius: 8,
                                            color: Color(0x26000000),
                                          ),
                                        ],
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.open_in_full, size: 18),
                                            SizedBox(width: AppSpacing.xs),
                                            Text('Ver mapa'),
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
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
