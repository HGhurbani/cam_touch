// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/services/auth_service.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_styles.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/client/screens/client_dashboard_screen.dart';
import 'features/client/screens/client_splash_screen.dart';
import 'features/photographer/screens/photographer_dashboard_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'routes/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      fontFamily: 'Tajawal',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnSecondary,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // أنماط شريط التطبيق
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppStyles.headline4.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      
      // أنماط الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppStyles.primaryButtonStyle,
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppStyles.outlineButtonStyle,
      ),
      
      // أنماط البطاقات
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 4,
        shadowColor: AppColors.shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
        ),
      ),
      
      // أنماط الحقول
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          borderSide: BorderSide(color: AppColors.primaryWithOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          borderSide: BorderSide(color: AppColors.primaryWithOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // أنماط الأيقونات
      iconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
      
      // أنماط النصوص
      textTheme: const TextTheme(
        headlineLarge: AppStyles.headline1,
        headlineMedium: AppStyles.headline2,
        headlineSmall: AppStyles.headline3,
        titleLarge: AppStyles.headline4,
        bodyLarge: AppStyles.body1,
        bodyMedium: AppStyles.body2,
        labelLarge: AppStyles.button,
      ),
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      fontFamily: 'Tajawal',
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnSecondary,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      
      // أنماط شريط التطبيق للوضع المظلم
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppStyles.headline4.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      
      // أنماط الأزرار للوضع المظلم
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppStyles.primaryButtonStyle,
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppStyles.outlineButtonStyle,
      ),
      
      // أنماط البطاقات للوضع المظلم
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shadowColor: AppColors.shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
        ),
      ),
      
      // أنماط الحقول للوضع المظلم
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          borderSide: BorderSide(color: AppColors.primaryWithOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          borderSide: BorderSide(color: AppColors.primaryWithOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // أنماط الأيقونات للوضع المظلم
      iconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
      
      // أنماط النصوص للوضع المظلم
      textTheme: const TextTheme(
        headlineLarge: AppStyles.headline1,
        headlineMedium: AppStyles.headline2,
        headlineSmall: AppStyles.headline3,
        titleLarge: AppStyles.headline4,
        bodyLarge: AppStyles.body1,
        bodyMedium: AppStyles.body2,
        labelLarge: AppStyles.button,
      ),
    );

    return MaterialApp(
      title: 'كام تاتش',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      
      // استخدام consumer للاستماع لحالة المصادقة وإعادة التوجيه
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          if (authService.currentUser != null) {
            if (authService.userRole == UserRole.client) {
              return const ClientDashboardScreen();
            } else if (authService.userRole == UserRole.photographer) {
              return const PhotographerDashboardScreen();
            } else if (authService.userRole == UserRole.admin) {
              return const AdminDashboardScreen();
            }
          }
          return const ClientSplashScreen();
        },
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}