// lib/features/admin/screens/admin_photographers_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/photographer_model.dart';
import '../../../core/models/user_model.dart'; // نحتاج لبيانات المستخدم الأساسية
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/loading_indicator.dart';

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
      appBar: AppBar(
        title: const Text('إدارة المصورين'),
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
      body: StreamBuilder<List<PhotographerModel>>(
        stream: firestoreService.getAllPhotographers(), // جلب جميع المصورين
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

          final photographers = snapshot.data!;
          return ListView.builder(
            itemCount: photographers.length,
            itemBuilder: (context, index) {
              final photographer = photographers[index];
              return FutureBuilder<UserModel?>( // جلب بيانات المستخدم الأساسية للمصور
                future: firestoreService.getUser(photographer.uid),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('تحميل المصور...'),
                    );
                  }
                  if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
                    return ListTile(
                      title: Text('خطأ في جلب بيانات المصور ${photographer.uid}'),
                    );
                  }

                  final user = userSnapshot.data!;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: Text(user.fullName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('البريد الإلكتروني: ${user.email}'),
                          Text('المتخصصات: ${photographer.specialties.join(', ')}'),
                          Text('التقييم: ${photographer.rating.toStringAsFixed(1)}'),
                          Text('الرصيد: \$${photographer.balance.toStringAsFixed(2)}'),
                        ],
                      ),
                      onTap: () {
                        // الانتقال لشاشة تفاصيل المصور وتعديل بياناته/رصيده
                        // Navigator.of(context).push(MaterialPageRoute(builder: (_) => PhotographerDetailScreen(photographerId: photographer.uid)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('سيتم الانتقال إلى تفاصيل المصور قريباً!')),
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