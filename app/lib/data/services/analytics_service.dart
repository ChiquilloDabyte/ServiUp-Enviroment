import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> logSignUp(String role) =>
      logEvent('sign_up', parameters: {'role': role});

  Future<void> logRequestCreated(String category) =>
      logEvent('request_created', parameters: {'category': category});

  Future<void> logOfferSent(String requestId) =>
      logEvent('offer_sent', parameters: {'request_id': requestId});

  Future<void> logServiceCompleted(String requestId) =>
      logEvent('service_completed', parameters: {'request_id': requestId});
}
