// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/client/screens/client_splash_screen.dart';
import '../features/client/screens/client_dashboard_screen.dart';
import '../features/photographer/screens/photographer_dashboard_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/client/screens/booking_screen.dart';
import '../features/admin/screens/admin_bookings_management_screen.dart';
import '../features/admin/screens/booking_detail_screen.dart';
import '../features/admin/screens/admin_add_booking_screen.dart';
import '../features/admin/screens/admin_photographers_management_screen.dart';
import '../features/admin/screens/admin_clients_management_screen.dart';
import '../features/admin/screens/admin_events_scheduling_screen.dart';
import '../features/admin/screens/admin_reports_screen.dart';
import '../features/admin/screens/admin_photographer_accounts_screen.dart';
import '../features/admin/screens/reports/attendance_report_screen.dart';
import '../features/admin/screens/reports/photographer_financial_report_screen.dart';
import '../features/admin/screens/reports/client_financial_report_screen.dart';
import '../features/client/screens/client_rewards_screen.dart';
import '../features/photographer/screens/photographer_deductions_screen.dart';
import '../features/photographer/screens/photographer_schedule_screen.dart'; // استيراد جديد

class AppRouter {
  static const String loginRoute = '/login';
  static const String clientSplashRoute = '/splash';
  static const String registerRoute = '/register';
  static const String clientDashboardRoute = '/client_dashboard';
  static const String photographerDashboardRoute = '/photographer_dashboard';
  static const String adminDashboardRoute = '/admin_dashboard';
  static const String bookingRoute = '/booking';
  static const String adminAddBookingRoute = '/admin_add_booking';
  static const String adminBookingsManagementRoute = '/admin_bookings_management';
  static const String bookingDetailRoute = '/booking_detail';
  static const String adminPhotographersManagementRoute = '/admin_photographers_management';
  static const String adminClientsManagementRoute = '/admin_clients_management';
  static const String adminEventsSchedulingRoute = '/admin_events_scheduling';
  static const String adminReportsRoute = '/admin_reports';
  static const String adminPhotographerAccountsRoute = '/admin_photographer_accounts';
  static const String attendanceReportRoute = '/admin_reports/attendance';
  static const String photographerFinancialReportRoute =
      '/admin_reports/photographers_financial';
  static const String clientFinancialReportRoute =
      '/admin_reports/clients_financial';
  static const String clientRewardsRoute = '/client_rewards';
  static const String photographerDeductionsRoute = '/photographer_deductions';
  static const String photographerScheduleRoute = '/photographer_schedule'; // مسار جديد

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case clientSplashRoute:
        return MaterialPageRoute(builder: (_) => const ClientSplashScreen());
      case registerRoute:
        final args = settings.arguments;
        return MaterialPageRoute(builder: (_) => RegisterScreen(initialRole: args is UserRole ? args : null));
      case clientDashboardRoute:
        return MaterialPageRoute(builder: (_) => const ClientDashboardScreen());
      case photographerDashboardRoute:
        return MaterialPageRoute(builder: (_) => const PhotographerDashboardScreen());
      case adminDashboardRoute:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case bookingRoute:
        return MaterialPageRoute(builder: (_) => const BookingScreen());
      case adminAddBookingRoute:
        return MaterialPageRoute(builder: (_) => const AdminAddBookingScreen());
      case adminBookingsManagementRoute:
        return MaterialPageRoute(builder: (_) => const AdminBookingsManagementScreen());
      case bookingDetailRoute:
        final args = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: args));
      case adminPhotographersManagementRoute:
        return MaterialPageRoute(builder: (_) => const AdminPhotographersManagementScreen());
      case adminClientsManagementRoute:
        return MaterialPageRoute(builder: (_) => const AdminClientsManagementScreen());
      case adminEventsSchedulingRoute:
        return MaterialPageRoute(builder: (_) => const AdminEventsSchedulingScreen());
      case adminReportsRoute:
        return MaterialPageRoute(builder: (_) => const AdminReportsScreen());
      case adminPhotographerAccountsRoute:
        return MaterialPageRoute(builder: (_) => const AdminPhotographerAccountsScreen());
      case attendanceReportRoute:
        return MaterialPageRoute(builder: (_) => const AttendanceReportScreen());
      case photographerFinancialReportRoute:
        return MaterialPageRoute(builder: (_) =>
            const PhotographerFinancialReportScreen());
      case clientFinancialReportRoute:
        return MaterialPageRoute(builder: (_) => const ClientFinancialReportScreen());
      case clientRewardsRoute:
        return MaterialPageRoute(builder: (_) => const ClientRewardsScreen());
      case photographerDeductionsRoute:
        return MaterialPageRoute(builder: (_) => const PhotographerDeductionsScreen());
      case photographerScheduleRoute: // حالة المسار الجديد
        return MaterialPageRoute(builder: (_) => const PhotographerScheduleScreen());

      default:
        return MaterialPageRoute(builder: (_) => const Text('Error: Unknown route'));
    }
  }
}