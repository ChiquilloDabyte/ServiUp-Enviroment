import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_model.dart';
import '../repositories/service_request_repository.dart';

class DashboardProvider with ChangeNotifier {
  final ServiceRequestRepository _serviceRequestRepository;

  DashboardProvider({required ServiceRequestRepository serviceRequestRepository})
      : _serviceRequestRepository = serviceRequestRepository;

  List<User> _providers = [];
  List<String> _providerActiveJobs = [];

  List<User> get providers => _providers;
  List<String> get providerActiveJobs => _providerActiveJobs;

  Future<void> fetchProviders() async {
    final providers = await _serviceRequestRepository.getProviders();
    _providers = providers;
    notifyListeners();
  }

  Future<void> fetchProviderActiveJobs(String providerId) async {
    final providerActiveJobs = await _serviceRequestRepository.watchProviderActiveJobs(providerId);
    _providerActiveJobs = providerActiveJobs.map((request) => request.id).toList();
    notifyListeners();
  }
}
