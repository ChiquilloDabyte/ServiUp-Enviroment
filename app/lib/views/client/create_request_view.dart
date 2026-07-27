import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/logger/app_logger.dart';
import '../../core/theme/app_dimensions.dart';
import '../../data/services/places_service.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/places_search_viewmodel.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/request_form_sections.dart';
import '../../widgets/responsive_content.dart';

class CreateRequestView extends ConsumerStatefulWidget {
  const CreateRequestView({super.key});

  @override
  ConsumerState<CreateRequestView> createState() => _CreateRequestViewState();
}

class _CreateRequestViewState extends ConsumerState<CreateRequestView> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late final TextEditingController _addressController;
  final _addressFocusNode = FocusNode();
  String? _category;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 2));
  double _latitude = 4.711;
  double _longitude = -74.0721;
  String _address = 'Bogotá, Colombia';
  String? _error;
  int _locationUpdateId = 0;
  bool _isResolvingAddress = false;
  bool _addressCoordinatesConfirmed = true;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: _address);
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final updateId = ++_locationUpdateId;
    try {
      final location =
          await ref.read(locationServiceProvider).getCurrentLocation();
      if (!mounted || updateId != _locationUpdateId) return;
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        _address = location.address;
        _addressCoordinatesConfirmed = true;
      });
      _setAddressText(location.address);
    } catch (e, stack) {
      AppLogger.warning('Failed to load initial location', e, stack);
    }
  }

  Future<void> _updateLocation(double latitude, double longitude) async {
    final updateId = ++_locationUpdateId;
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      _isResolvingAddress = true;
    });

    final address = await ref
        .read(locationServiceProvider)
        .getAddressFromCoordinates(latitude: latitude, longitude: longitude);
    if (!mounted || updateId != _locationUpdateId) return;

    setState(() {
      _address = address;
      _isResolvingAddress = false;
      _addressCoordinatesConfirmed = true;
    });
    _setAddressText(address);
    ref.read(placesSearchViewModelProvider.notifier).dismissSuggestions();
  }

  void _onAddressChanged(String value) {
    _locationUpdateId++;
    setState(() {
      _address = value;
      _addressCoordinatesConfirmed = false;
      _isResolvingAddress = false;
    });
    ref
        .read(placesSearchViewModelProvider.notifier)
        .search(query: value, latitude: _latitude, longitude: _longitude);
  }

  Future<void> _selectAddress(PlaceSuggestion suggestion) async {
    _locationUpdateId++;
    try {
      final selection = await ref
          .read(placesSearchViewModelProvider.notifier)
          .selectAddress(suggestion);
      if (!mounted) return;

      setState(() {
        _latitude = selection.latitude;
        _longitude = selection.longitude;
        _address = selection.address;
        _addressCoordinatesConfirmed = true;
      });
      _setAddressText(selection.address);
      _addressFocusNode.unfocus();
    } catch (error, stackTrace) {
      AppLogger.warning('Failed to select Places address', error, stackTrace);
    }
  }

  void _setAddressText(String address) {
    _addressController.value = TextEditingValue(
      text: address,
      selection: TextSelection.collapsed(offset: address.length),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _scheduledAt,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _category == null) {
      setState(() => _error = 'Selecciona una categoría.');
      return;
    }

    if (!_addressCoordinatesConfirmed) {
      setState(() {
        _error = null;
        _isResolvingAddress = true;
      });
      try {
        final location = await ref
            .read(locationServiceProvider)
            .getLocationFromAddress(_addressController.text);
        if (!mounted) return;
        setState(() {
          _latitude = location.latitude;
          _longitude = location.longitude;
          _address = location.address;
          _addressCoordinatesConfirmed = true;
          _isResolvingAddress = false;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _error = repositoryErrorMessage(error);
          _isResolvingAddress = false;
        });
        return;
      }
    }

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    setState(() => _error = null);

    try {
      final requestId = await ref
          .read(serviceRequestViewModelProvider.notifier)
          .createRequest(
            clientId: user.id,
            category: _category!,
            description: _descriptionController.text,
            latitude: _latitude,
            longitude: _longitude,
            address: _address,
            scheduledAt: _scheduledAt,
          );
      if (mounted) context.pushReplacement('/requests/$requestId');
    } catch (e) {
      if (mounted) setState(() => _error = repositoryErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final placesState = ref.watch(placesSearchViewModelProvider);
    final isLoading =
        ref.watch(serviceRequestViewModelProvider).isLoading ||
        placesState.isSelecting ||
        _isResolvingAddress;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva solicitud')),
      body: SingleChildScrollView(
        child: ResponsiveContent(
          maxWidth: 800,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cuéntanos qué necesitas',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Agrega los detalles para recibir propuestas más precisas.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpacing.gutter),
                ],
                ServiceDetailsFormSection(
                  category: _category,
                  onCategoryChanged:
                      (value) => setState(() => _category = value),
                  descriptionController: _descriptionController,
                  scheduledAt: _scheduledAt,
                  onPickDateTime: _pickDateTime,
                ),
                const SizedBox(height: AppSpacing.md),
                RequestLocationFormSection(
                  addressController: _addressController,
                  addressFocusNode: _addressFocusNode,
                  suggestions: placesState.suggestions,
                  isBusy: placesState.isSearching || placesState.isSelecting,
                  coordinatesConfirmed: _addressCoordinatesConfirmed,
                  latitude: _latitude,
                  longitude: _longitude,
                  onAddressChanged: _onAddressChanged,
                  onAddressSubmitted: () {
                    ref
                        .read(placesSearchViewModelProvider.notifier)
                        .dismissSuggestions();
                  },
                  onSuggestionSelected: (suggestion) {
                    unawaited(_selectAddress(suggestion));
                  },
                  onLocationChanged: (lat, lng) {
                    unawaited(_updateLocation(lat, lng));
                  },
                  error: placesState.error,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: const Icon(Icons.publish_outlined),
                  label: Text(
                    isLoading ? 'Publicando...' : 'Publicar solicitud',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
