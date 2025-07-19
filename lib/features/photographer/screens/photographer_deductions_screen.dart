// lib/features/photographer/screens/photographer_deductions_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // لفتح Google Maps

import '../../../core/models/attendance_model.dart';
import '../../../core/models/event_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart'; // لربط التنقل (في حال الحاجة)
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_app_bar.dart';

class PhotographerDeductionsScreen extends StatelessWidget {
  const PhotographerDeductionsScreen({super.key});

  // دالة لفتح الموقع على خرائط جوجل
  void _launchGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      debugPrint('Could not launch $url');
      // يمكن عرض SnackBar للمستخدم يفيد بالفشل
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('تعذر فتح الخريطة.')),
      // );
    }
  }

  @override
  Widget build(BuildContext buildContext) { // Changed context to buildContext to avoid conflict
    final authService = Provider.of<AuthService>(buildContext);
    final firestoreService = Provider.of<FirestoreService>(buildContext);

    // التحقق الأمني: التأكد أن المستخدم مسجل دخول ودوره "مصور"
    if (authService.currentUser == null || authService.userRole != UserRole.photographer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(buildContext).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const LoadingIndicator();
    }

    final String currentPhotographerId = authService.currentUser!.uid;

    return Scaffold(
      appBar: const CustomAppBar(title: 'تقارير الخصومات'),
      body: StreamBuilder<List<AttendanceModel>>(
        // جلب جميع سجلات الحضور للمصور الحالي
        stream: firestoreService.getPhotographerAttendanceForEvent(currentPhotographerId, ''), // يتم تجاهل eventId هنا لجلب الكل
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد سجلات حضور/انصراف لعرضها.'));
          }

          // تصفية السجلات لعرض الخصومات فقط (التي كانت متأخرة وتم تطبيق خصم عليها)
          final deductionRecords = snapshot.data!.where(
                  (record) => record.isLate && record.lateDeductionApplied != null && record.lateDeductionApplied! > 0
          ).toList();

          if (deductionRecords.isEmpty) {
            return const Center(child: Text('لا توجد خصومات مسجلة حالياً.'));
          }

          return ListView.builder(
            itemCount: deductionRecords.length,
            itemBuilder: (context, index) {
              final record = deductionRecords[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نوع السجل: ${record.type == 'check_in' ? 'تسجيل حضور' : 'تسجيل انصراف'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('التاريخ والوقت: ${DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp.toLocal())}'),
                      // جلب اسم الفعالية المرتبطة
                      FutureBuilder<EventModel?>(
                        future: firestoreService.getEvent(record.eventId),
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.hasData && eventSnapshot.data != null) {
                            return Text('الفعالية: ${eventSnapshot.data!.title}');
                          }
                          return Text('الفعالية ID: ${record.eventId}');
                        },
                      ),
                      Text(
                        'مبلغ الخصم: \$${record.lateDeductionApplied!.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('موقع التسجيل: ${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}'),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.map),
                          label: const Text('عرض الموقع على الخريطة'),
                          onPressed: () => _launchGoogleMaps(record.latitude, record.longitude),
                        ),
                      ),
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
