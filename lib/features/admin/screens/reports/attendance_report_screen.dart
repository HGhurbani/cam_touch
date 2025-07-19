// lib/features/admin/screens/reports/attendance_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // لفتح Google Maps

import '../../../../core/models/attendance_model.dart';
import '../../../../core/models/user_model.dart'; // لجلب اسم المصور
import '../../../../core/models/event_model.dart'; // لجلب اسم الفعالية
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

class AttendanceReportScreen extends StatelessWidget {
  const AttendanceReportScreen({super.key});

  // دالة لفتح الموقع على خرائط جوجل
  void _launchGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      debugPrint('Could not launch $url');
    }
  }

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
        title: const Text('تقارير الحضور والانصراف'),
      ),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: firestoreService.getAllAttendanceRecords(),
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

          final attendanceRecords = snapshot.data!;
          return ListView.builder(
            itemCount: attendanceRecords.length,
            itemBuilder: (context, index) {
              final record = attendanceRecords[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<UserModel?>(
                        future: firestoreService.getUser(record.photographerId),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.hasData && userSnapshot.data != null) {
                            return Text('المصور: ${userSnapshot.data!.fullName}', style: const TextStyle(fontWeight: FontWeight.bold));
                          }
                          return Text('المصور ID: ${record.photographerId}', style: const TextStyle(fontWeight: FontWeight.bold));
                        },
                      ),
                      FutureBuilder<EventModel?>(
                        future: firestoreService.getEvent(record.eventId),
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.hasData && eventSnapshot.data != null) {
                            return Text('الفعالية: ${eventSnapshot.data!.title}');
                          }
                          return Text('الفعالية ID: ${record.eventId}');
                        },
                      ),
                      Text('النوع: ${record.type == 'check_in' ? 'حضور' : 'انصراف'}'),
                      Text('الوقت: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp)}'),
                      Text('الإحداثيات: ${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}'),
                      if (record.isLate)
                        Text(
                          'متأخر: نعم (خصم: \$${record.lateDeductionApplied?.toStringAsFixed(2) ?? '0.00'})',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 8),
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