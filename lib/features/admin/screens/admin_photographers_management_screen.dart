// lib/features/admin/screens/admin_photographers_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/photographer_model.dart';
import '../../../core/models/user_model.dart'; // نحتاج لبيانات المستخدم الأساسية
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_app_bar.dart';

class AdminPhotographersManagementScreen extends StatefulWidget {
  const AdminPhotographersManagementScreen({super.key});

  @override
  State<AdminPhotographersManagementScreen> createState() => _AdminPhotographersManagementScreenState();
}

class _AdminPhotographersManagementScreenState extends State<AdminPhotographersManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    if (authService.currentUser == null || authService.userRole != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const LoadingIndicator();
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'إدارة المصورين',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // الانتقال لشاشة إضافة مصور جديد (تسجيل حساب جديد بدور "مصور")
              Navigator.of(context).pushNamed(AppRouter.registerRoute, arguments: UserRole.photographer);
            },
            tooltip: 'إضافة مصور جديد',
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>( 
        stream: firestoreService.getAllPhotographerUsers(), // جلب جميع المستخدمين بدور مصور
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد مصورون لعرضهم حالياً.'));
          }

          final photographerUsers = snapshot.data!;
          return ListView.builder(
            itemCount: photographerUsers.length,
            itemBuilder: (context, index) {
              final user = photographerUsers[index];
              return FutureBuilder<PhotographerModel?>( // جلب بيانات المصور التفصيلية إن وجدت
                future: firestoreService.getPhotographerData(user.uid),
                builder: (context, photoSnapshot) {
                  final photographer = photoSnapshot.data;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: Text(user.fullName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('رقم الهاتف: ${user.phoneNumber ?? '-'}'),
                          if (photographer != null) ...[
                            Text('المتخصصات: ${photographer.specialties.join(', ')}'),
                            Text('التقييم: ${photographer.rating.toStringAsFixed(1)}'),
                            Text('الرصيد: ${photographer.balance.toStringAsFixed(2)} ريال يمني'),
                            Text('إجمالي الخصومات: ${photographer.totalDeductions.toStringAsFixed(2)} ريال يمني'),
                          ]
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRouter.photographerDetailRoute,
                          arguments: user.uid,
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}