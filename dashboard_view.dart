import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_model.dart';
import '../../models/enums/user_role.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/request_list_widget.dart';

class DashboardView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    if (authProvider.user == null) {
      return Center(child: CircularProgressIndicator());
    }

    final userRole = authProvider.user!.role;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (userRole == UserRole.provider)
              Expanded(
                child: RequestListWidget(
                  requests: dashboardProvider.providerActiveJobs,
                  title: 'Mis Trabajos Activos',
                ),
              )
            else
              FutureBuilder<List<User>>(
                future: dashboardProvider.getProviders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final providers = snapshot.data!;
                    return Expanded(
                      child: RequestListWidget(
                        requests: providers.map((user) => user.id).toList(),
                        title: 'Prestadores',
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
