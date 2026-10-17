import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'auth/login_view.dart';
import 'citizen/citizen_home_view.dart';
import 'driver/dashboard_view.dart';

class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (auth.currentUser?.isAuthenticated == true) {
      if (auth.currentUser?.role == UserRole.driver) {
        return const DashboardView();
      } else {
        return const CitizenHomeView();
      }
    } else {
      return const LoginView();
    }
  }
}
