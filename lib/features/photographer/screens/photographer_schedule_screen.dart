// lib/features/photographer/screens/photographer_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // لاستخدام Timestamp

import '../../../core/models/event_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_app_bar.dart';

class PhotographerScheduleScreen extends StatelessWidget {
  const PhotographerScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    // التحقق الأمني: التأكد أن المستخدم مسجل دخول ودوره "مصور"
    if (authService.currentUser == null || authService.userRole != UserRole.photographer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const LoadingIndicator();
    }

    final String currentPhotographerId = authService.currentUser!.uid;

    return Scaffold(
      appBar: const CustomAppBar(title: 'جدولي الزمني'),
      body: StreamBuilder<List<EventModel>>(
        // جلب جميع الفعاليات المجدولة للمصور الحالي
        stream: firestoreService.getPhotographerEvents(currentPhotographerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد فعاليات مجدولة لك حالياً في جدولك.'));
          }

          final events = snapshot.data!;
          // يمكن هنا إضافة تبويبات (Tabs) لـ "قادم" و "منتهي" إذا كانت القائمة طويلة جداً
          // أو تصفية الفعاليات حسب التاريخ

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الفعالية: ${event.title}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('الحالة: ${event.status}'),
                      Text('التاريخ والوقت: ${DateFormat('yyyy-MM-dd HH:mm').format(event.eventDateTime.toLocal())}'),
                      Text('الموقع: ${event.location}'),
                      Text('خصم التأخير المحتمل: ${event.lateDeductionAmount.toStringAsFixed(2)} ريال يمني'),
                      Text('مدة السماح بالتأخير: ${event.gracePeriodMinutes} دقيقة'),
                      // يمكن إضافة المزيد من التفاصيل هنا أو زر "عرض تفاصيل الحجز"
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}