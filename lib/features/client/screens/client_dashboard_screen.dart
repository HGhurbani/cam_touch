// lib/features/client/screens/client_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/booking_model.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'booking_screen.dart'; // تأكد من هذا الاستيراد
import 'client_rewards_screen.dart'; // استيراد جديد

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  // يمكننا جلب بيانات العميل هنا إذا أردنا عرض اسمه
  // UserModel? _clientUser;

  @override
  void initState() {
    super.initState();
    // _loadClientData(); // يمكن تفعيل هذا لاسترداد بيانات العميل
  }

  // Future<void> _loadClientData() async {
  //   final authService = Provider.of<AuthService>(context, listen: false);
  //   final firestoreService = Provider.of<FirestoreService>(context, listen: false);
  //   if (authService.currentUser != null) {
  //     _clientUser = await firestoreService.getUser(authService.currentUser!.uid);
  //     setState(() {});
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    // التحقق من حالة المستخدم ودوره (للتأكد من أن هذا العميل بالفعل)
    if (authService.currentUser == null || authService.userRole != UserRole.client) {
      // إذا لم يكن هناك مستخدم أو كان الدور خاطئًا، أعد التوجيه إلى شاشة تسجيل الدخول
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const LoadingIndicator(); // عرض مؤشر تحميل أثناء إعادة التوجيه
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم العميل'),
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
              'مرحبًا بك يا ${authService.currentUser?.email ?? 'عميل'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'حجز جلسة تصوير جديدة',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BookingScreen()),
                );
              },
            ),
            const SizedBox(height: 16), // مسافة بين الأزرار
            CustomButton(
              text: 'نقاطي ومكافآتي',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ClientRewardsScreen()),
                );
              },
              color: Colors.deepOrange, // لون مميز لزر المكافآت
            ),
            const SizedBox(height: 30),
            const Text(
              'حجوزاتي الأخيرة:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              // StreamBuilder للاستماع إلى تغييرات الحجوزات في الوقت الفعلي
              child: StreamBuilder<List<BookingModel>>(
                stream: firestoreService.getClientBookings(authService.currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator();
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('لا توجد حجوزات حتى الآن.'));
                  }

                  final bookings = snapshot.data!;
                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الخدمة: ${booking.serviceType}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('التاريخ: ${booking.bookingDate.toLocal().toString().split(' ')[0]}'),
                              Text('الوقت: ${booking.bookingTime}'),
                              Text('الحالة: ${booking.status}'),
                              if (booking.photographerId != null)
                                Text('المصور المعين ID: ${booking.photographerId}'),
                              // يمكنك إضافة زر لعرض تفاصيل الحجز أو الفاتورة هنا
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}