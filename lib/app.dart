// lib/app.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart'; // We will create this
import 'features/client/screens/client_dashboard_screen.dart'; // We will create this
import 'features/photographer/screens/photographer_dashboard_screen.dart'; // We will create this
import 'features/admin/screens/admin_dashboard_screen.dart'; // We will create this
import 'routes/app_router.dart'; // We will create this

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cam Touch',
      debugShowCheckedModeBanner: false, // Set to false for production
      theme: ThemeData(
        primarySwatch: Colors.blue, // You can customize your theme later
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      // Use consumer to listen to auth state and redirect accordingly
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          // This will handle initial routing based on authentication state
          // and user role once we implement it in AuthService.
          // For now, it will simply go to LoginScreen.
          // Later:
          // if (authService.user != null) {
          //   if (authService.userRole == 'client') return ClientDashboardScreen();
          //   if (authService.userRole == 'photographer') return PhotographerDashboardScreen();
          //   if (authService.userRole == 'admin') return AdminDashboardScreen();
          // }
          return const LoginScreen(); // Default to login screen
        },
      ),
      onGenerateRoute: AppRouter.onGenerateRoute, // For named routes
    );
  }
}