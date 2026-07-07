import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/providers/app_providers.dart';
import '../../domain/viewmodels/auth_viewmodel.dart';
import '../../models/enums/user_role.dart';
import '../../widgets/loading_view.dart';
import '../client/client_home_view.dart';
import '../provider/provider_home_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);

    return profile.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (error, _) => Scaffold(
        body: Center(child: Text(authErrorMessage(error))),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Sin sesión')));
        }

        if (!user.profileComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/onboarding');
          });
          return const Scaffold(body: LoadingView(message: 'Completando perfil...'));
        }

        return user.role == UserRole.client
            ? const ClientHomeView()
            : const ProviderHomeView();
      },
    );
  }
}
