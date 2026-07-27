class AppConstants {
  AppConstants._();

  static const String appName = 'ServiUp';
  static const String usersCollection = 'users';
  static const String providerPublicProfilesCollection =
      'provider_public_profiles';
  static const String serviceRequestsCollection = 'service_requests';
  static const String openRequestListingsCollection = 'open_request_listings';
  static const String offersCollection = 'offers';
  static const String chatsCollection = 'chats';
  static const String notificationsCollection = 'notifications';
  static const String reviewsCollection = 'reviews';

  static const double defaultSearchRadiusKm = 25;
  static const int defaultPageSize = 20;
  static const int maxImageSizeBytes = 5 * 1024 * 1024;
  static const int maxChatMessageLength = 2000;
  static const int chatPageSize = 50;

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
