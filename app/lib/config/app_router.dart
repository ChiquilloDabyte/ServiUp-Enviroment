import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/providers/app_providers.dart';
import '../models/enums/user_role.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/auth/email_verification_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/phone_verification_view.dart';
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
import '../views/maps/request_location_map_view.dart';
import '../views/provider/provider_request_detail_view.dart';
import '../views/profile/edit_profile_view.dart';
import '../views/profile/profile_view.dart';
import '../views/review/service_review_view.dart';
import '../views/splash/splash_view.dart';
import '../widgets/main_navigation_shell.dart';
import 'route_arguments.dart';

enum AuthRouteState { loading, signedOut, signedIn }

enum ProfileRouteState { loading, error, missing, incomplete, complete }

String? resolveAppRedirect({
  required String matchedLocation,
  required AuthRouteState authState,
  required ProfileRouteState profileState,
  UserRole? userRole,
}) {
  if (matchedLocation == '/splash') return null;

  final loggingIn =
      matchedLocation == '/login' ||
      matchedLocation == '/register' ||
      matchedLocation == '/forgot-password';
  final isPublicLegal =
      matchedLocation == '/terms' || matchedLocation == '/privacy';

  if (authState == AuthRouteState.loading) return null;
  if (authState == AuthRouteState.signedOut) {
    return loggingIn || isPublicLegal ? null : '/login';
  }

  if (profileState == ProfileRouteState.loading) return null;
  if (profileState == ProfileRouteState.error) return null;
  if (profileState == ProfileRouteState.missing) {
    return matchedLocation == '/onboarding' ? null : '/onboarding';
  }
  if (matchedLocation == '/offline' && userRole == UserRole.provider) {
    return '/home';
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final profile = ref.read(currentUserProfileProvider);

      final authRouteState =
          !authState.hasValue
              ? AuthRouteState.loading
              : authState.value == null
              ? AuthRouteState.signedOut
              : AuthRouteState.signedIn;

      final ProfileRouteState profileRouteState;
      if (profile.hasError && !profile.hasValue) {
        profileRouteState = ProfileRouteState.error;
      } else if (!profile.hasValue) {
        profileRouteState = ProfileRouteState.loading;
      } else {
        final userProfile = profile.value;
        profileRouteState =
            userProfile == null
                ? ProfileRouteState.missing
                : userProfile.profileComplete
                ? ProfileRouteState.complete
                : ProfileRouteState.incomplete;
      }

      return resolveAppRedirect(
        matchedLocation: state.matchedLocation,
        authState: authRouteState,
        profileState: profileRouteState,
        userRole: profile.value?.role,
      );
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
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationView(),
      ),
      GoRoute(
        path: '/verify-phone',
        builder: (context, state) => const PhoneVerificationView(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingView(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(
            currentIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatsView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileView(),
      ),
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
        path: '/requests/:id/review',
        builder: (context, state) {
          return ServiceReviewView(requestId: state.pathParameters['id']!);
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
        path: '/request-location',
        builder: (context, state) {
          final extra = state.extra;
          return RequestLocationMapView(
            location: extra is RequestLocationMapArgs ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsView(),
      ),
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
