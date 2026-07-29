import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      error:
          (error, _) =>
              Scaffold(body: Center(child: Text(authErrorMessage(error)))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Sin sesión')));
        }

        return user.role == UserRole.client
            ? const ClientHomeView()
            : const ProviderHomeView();
      },
    );
  }
}
