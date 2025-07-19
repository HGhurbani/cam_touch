// lib/features/admin/screens/admin_bookings_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ

import '../../../core/models/booking_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'booking_detail_screen.dart'; // سنقوم بإنشاء هذه الشاشة تالياً

class AdminBookingsManagementScreen extends StatelessWidget {
  const AdminBookingsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    // تحقق من أن المستخدم هو مدير
    if (authService.currentUser == null || authService.userRole != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const LoadingIndicator();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحجوزات'),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: firestoreService.getAllBookings(), // جلب جميع الحجوزات
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد حجوزات لعرضها حالياً.'));
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text('${booking.clientName} - ${booking.serviceType}'),
                  subtitle: Text(
                    'التاريخ: ${DateFormat('yyyy-MM-dd').format(booking.bookingDate)}\n'
                        'الحالة: ${booking.status}',
                  ),
                  trailing: Icon(
                    _getBookingStatusIcon(booking.status),
                    color: _getBookingStatusColor(booking.status),
                  ),
                  onTap: () {
                    // الانتقال إلى شاشة تفاصيل الحجز
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BookingDetailScreen(bookingId: booking.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // دوال مساعدة لتحديد الأيقونة واللون بناءً على حالة الحجز
  IconData _getBookingStatusIcon(String status) {
    switch (status) {
      case 'pending_admin_approval':
        return Icons.pending_actions;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'deposit_paid':
        return Icons.payment;
      case 'completed':
        return Icons.done_all;
      case 'scheduled':
        return Icons.event_available;
      default:
        return Icons.info_outline;
    }
  }

  Color _getBookingStatusColor(String status) {
    switch (status) {
      case 'pending_admin_approval':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'deposit_paid':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'scheduled':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}