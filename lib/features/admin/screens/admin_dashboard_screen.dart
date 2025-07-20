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
import '../../../core/services/firestore_service.dart';
import '../../../core/models/user_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  UserModel? _adminUser;

  @override
  void initState() {
    super.initState();
    _loadAdminUser();
  }

  Future<void> _loadAdminUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (authService.currentUser != null) {
      _adminUser = await firestoreService.getUser(authService.currentUser!.uid);
      if (mounted) setState(() {});
    }
  }

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
              'مرحبًا بك يا ${_adminUser?.fullName ?? authService.currentUser?.email ?? 'مدير'}!',
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
              text: 'حجوزاتي',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.adminMyBookingsRoute);
              },
              color: Colors.orange,
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
              text: 'إدارة حسابات المصورين',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.adminPhotographerAccountsRoute);
              },
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'إدارة العملاء',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.adminClientsManagementRoute);
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
              text: 'إدارة الحضور والغياب',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.adminAttendanceManagementRoute);
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
