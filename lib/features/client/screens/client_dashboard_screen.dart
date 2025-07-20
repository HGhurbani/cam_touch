// lib/features/client/screens/client_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/models/user_model.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/dialogs/confirmation_dialog.dart';
import 'booking_screen.dart'; // تأكد من هذا الاستيراد
import 'client_rewards_screen.dart'; // استيراد جديد
import '../../../core/utils/status_utils.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  // متغير لتخزين بيانات العميل لجلب الاسم الكامل
  UserModel? _clientUser;

  @override
  void initState() {
    super.initState();
    _loadClientData(); // جلب بيانات العميل لعرض اسمه
  }

  Future<void> _loadClientData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (authService.currentUser != null) {
      _clientUser = await firestoreService.getUser(authService.currentUser!.uid);
      if (mounted) setState(() {});
    }
  }

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
      appBar: CustomAppBar(
        title: 'لوحة تحكم العميل',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => const ConfirmationDialog(
                  title: 'تأكيد تسجيل الخروج',
                  content: 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
                ),
              );
              if (confirm == true) {
                await authService.signOut();
              }
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
              'مرحبًا بك يا ${_clientUser?.fullName ?? authService.currentUser?.email ?? 'عميل'}!',
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
                Navigator.of(context).pushNamed(AppRouter.clientRewardsRoute);
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
                              Text('الحالة: ${getBookingStatusLabel(booking.status)}'),
                              if (booking.photographerIds != null && booking.photographerIds!.isNotEmpty)
                                FutureBuilder<List<UserModel?>>(
                                  future: Future.wait(booking.photographerIds!.map((id) => firestoreService.getUser(id))),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const SizedBox.shrink();
                                    }
                                    final names = snapshot.data
                                            ?.whereType<UserModel>()
                                            .map((u) => u.fullName)
                                            .join(', ') ??
                                        booking.photographerIds!.join(', ');
                                    return Text('المصورون: $names');
                                  },
                                ),
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