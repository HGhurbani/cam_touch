// lib/features/admin/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_app_bar.dart';
import 'admin_bookings_management_screen.dart';
// لاستعراض وإدارة بيانات المصورين
import 'admin_photographers_management_screen.dart';
// لجدولة المواعيد الخاصة بالفعاليات
import 'admin_events_scheduling_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.currentUser == null || authService.userRole != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const CircularProgressIndicator(); // أو LoadingIndicator
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'لوحة تحكم المدير',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحبًا بك يا ${authService.currentUser?.email ?? 'مدير'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // قائمة بأزرار التنقل لإدارة الأقسام المختلفة
            CustomButton(
              text: 'إدارة الحجوزات',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminBookingsManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'إدارة المصورين',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.adminPhotographersManagementRoute);
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'جدولة الفعاليات',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.adminEventsSchedulingRoute);
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'التقارير',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.adminReportsRoute);
              },
              color: Colors.teal, // لون مميز لزر التقارير
            ),
          ],
        ),
      ),
    );
  }
}
