import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/providers/app_providers.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/client/create_request_view.dart';
import '../views/client/request_detail_view.dart';
import '../views/chat/chat_view.dart';
import '../views/chat/chats_view.dart';
import '../views/home/home_view.dart';
import '../views/notifications/notifications_view.dart';
import '../views/offline/offline_providers_view.dart';
import '../views/onboarding/onboarding_view.dart';
import '../views/legal/privacy_policy_view.dart';
import '../views/legal/terms_conditions_view.dart';
import '../views/provider/provider_request_detail_view.dart';
import '../views/splash/splash_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final profile = ref.read(currentUserProfileProvider);
      final isSplash = state.matchedLocation == '/splash';
      if (isSplash) return null;

      final user = authState.value;
      final loggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (user == null) {
        return loggingIn ? null : '/login';
      }

      if (loggingIn) {
        return '/home';
      }

      final userProfile = profile.value;
      if (userProfile != null && !userProfile.profileComplete) {
        return state.matchedLocation == '/onboarding' ? null : '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashView()),
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeView()),
      GoRoute(
        path: '/requests/create',
        builder: (context, state) => const CreateRequestView(),
      ),
      GoRoute(
        path: '/requests/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClientRequestDetailView(requestId: id);
        },
      ),
      GoRoute(
        path: '/provider/requests/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProviderRequestDetailView(requestId: id);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsView(),
      ),
      GoRoute(path: '/chats', builder: (context, state) => const ChatsView()),
      GoRoute(
        path: '/chats/:id',
        builder: (context, state) {
          return ChatView(chatId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/offline',
        builder: (context, state) => const OfflineProvidersView(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsConditionsView(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyView(),
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProfileProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
