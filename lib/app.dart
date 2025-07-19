// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    const primaryColor = Color(0xFF024650);
    const secondaryColor = Color(0xFFFF9403);

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      fontFamily: 'Tajawal',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      fontFamily: 'Tajawal',
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );

    return MaterialApp(
      title: 'Cam Touch',
      debugShowCheckedModeBanner: false, // Set to false for production
      theme: lightTheme,
      darkTheme: darkTheme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
