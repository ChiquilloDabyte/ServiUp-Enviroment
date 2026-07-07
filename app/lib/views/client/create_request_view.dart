import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/service_request_viewmodel.dart';
import '../../widgets/category_dropdown.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/location_picker.dart';

class CreateRequestView extends ConsumerStatefulWidget {
  const CreateRequestView({super.key});

  @override
  ConsumerState<CreateRequestView> createState() => _CreateRequestViewState();
}

class _CreateRequestViewState extends ConsumerState<CreateRequestView> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _category;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 2));
  double _latitude = 4.711;
  double _longitude = -74.0721;
  String _address = 'Bogotá, Colombia';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final location = await ref.read(locationServiceProvider).getCurrentLocation();
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        _address = location.address;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
      if (mounted) context.go('/requests/$requestId');
    } catch (e) {
      setState(() => _error = repositoryErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(serviceRequestViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva solicitud')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              CategoryDropdown(
                value: _category,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del servicio',
                ),
                maxLines: 4,
                validator: (value) => value == null || value.length < 10
                    ? 'Describe el servicio con al menos 10 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha y hora'),
                subtitle: Text(_scheduledAt.toString()),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDateTime,
                ),
              ),
              const SizedBox(height: 8),
              Text(_address),
              const SizedBox(height: 8),
              LocationPicker(
                initialLatitude: _latitude,
                initialLongitude: _longitude,
                onLocationChanged: (lat, lng) {
                  setState(() {
                    _latitude = lat;
                    _longitude = lng;
                  });
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: Text(isLoading ? 'Publicando...' : 'Publicar solicitud'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
