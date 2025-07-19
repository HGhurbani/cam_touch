// lib/features/admin/screens/admin_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import 'reports/attendance_report_screen.dart'; // استيراد جديد لتقرير الحضور
import 'reports/photographer_financial_report_screen.dart'; // استيراد جديد لتقرير المصورين المالي
import 'reports/client_financial_report_screen.dart'; // استيراد جديد لتقرير العملاء المالي

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // تحقق من أن المستخدم هو مدير
    if (authService.currentUser == null || authService.userRole != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const CircularProgressIndicator();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر نوع التقرير:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'تقارير الحضور والانصراف',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AttendanceReportScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'تقارير المصورين المالية',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PhotographerFinancialReportScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'تقارير العملاء والدفعات',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ClientFinancialReportScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}