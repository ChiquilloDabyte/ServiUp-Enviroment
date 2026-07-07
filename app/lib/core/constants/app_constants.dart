class AppConstants {
  AppConstants._();

  static const String appName = 'ServiUp';
  static const String usersCollection = 'users';
  static const String serviceRequestsCollection = 'service_requests';
  static const String offersCollection = 'offers';
  static const String notificationsCollection = 'notifications';

  static const double defaultSearchRadiusKm = 25;
  static const int maxImageSizeBytes = 5 * 1024 * 1024;

  static const List<String> serviceCategories = [
    'Plomería',
    'Electricidad',
    'Limpieza',
    'Jardinería',
    'Pintura',
    'Carpintería',
    'Mudanzas',
    'Tecnología',
    'Otro',
  ];
}
