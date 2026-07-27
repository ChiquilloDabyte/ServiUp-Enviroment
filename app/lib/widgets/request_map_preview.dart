import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/theme/app_dimensions.dart';

class RequestMapPreview extends StatelessWidget {
  const RequestMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final position = LatLng(latitude, longitude);

    final colors = Theme.of(context).colorScheme;

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
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: position, zoom: 15),
              markers: {
                Marker(markerId: const MarkerId('request'), position: position),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}
