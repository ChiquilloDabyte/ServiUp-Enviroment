import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onLocationChanged,
  });

  final double initialLatitude;
  final double initialLongitude;
  final void Function(double latitude, double longitude) onLocationChanged;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late LatLng _position;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _position = LatLng(widget.initialLatitude, widget.initialLongitude);
  }

  @override
  void didUpdateWidget(covariant LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLatitude == oldWidget.initialLatitude &&
        widget.initialLongitude == oldWidget.initialLongitude) {
      return;
    }

    _position = LatLng(widget.initialLatitude, widget.initialLongitude);
    unawaited(_mapController?.animateCamera(CameraUpdate.newLatLng(_position)));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _position, zoom: 15),
          onMapCreated: (controller) => _mapController = controller,
          markers: {
            Marker(markerId: const MarkerId('selected'), position: _position),
          },
          onTap: (latLng) {
            setState(() => _position = latLng);
            widget.onLocationChanged(latLng.latitude, latLng.longitude);
          },
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
        ),
      ),
    );
  }
}
