// lib/features/admin/screens/reports/photographer_financial_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/photographer_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../../routes/app_router.dart';

class PhotographerFinancialReportScreen extends StatelessWidget {
  const PhotographerFinancialReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    if (authService.currentUser == null || authService.userRole != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute); // تحتاج AppRouter
      });
      return const LoadingIndicator();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير المصورين المالية'),
      ),
      body: StreamBuilder<List<PhotographerModel>>(
        stream: firestoreService.getAllPhotographers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد مصورون لعرض تقاريرهم.'));
          }

          final photographers = snapshot.data!;
          return ListView.builder(
            itemCount: photographers.length,
            itemBuilder: (context, index) {
              final photographer = photographers[index];
              return FutureBuilder<UserModel?>(
                future: firestoreService.getUser(photographer.uid),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasData && userSnapshot.data != null) {
                    final user = userSnapshot.data!;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المصور: ${user.fullName}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text('البريد الإلكتروني: ${user.email}'),
                            const SizedBox(height: 10),
                            Text('الرصيد الحالي: \$${photographer.balance.toStringAsFixed(2)}', style: TextStyle(color: photographer.balance >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                            Text('إجمالي الخصومات: \$${photographer.totalDeductions.toStringAsFixed(2)}'),
                            Text('عدد الحجوزات المكتملة: ${photographer.totalBookings}'),
                            // يمكن إضافة زر لعرض تفاصيل الخصومات لكل مصور
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink(); // أو مؤشر تحميل
                },
              );
            },
          );
        },
      ),
    );
  }
}
