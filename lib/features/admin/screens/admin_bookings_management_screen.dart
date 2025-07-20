// lib/features/admin/screens/admin_bookings_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ

import '../../../core/models/booking_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_app_bar.dart';
import 'booking_detail_screen.dart'; // سنقوم بإنشاء هذه الشاشة تالياً
import '../../../core/utils/status_utils.dart';

class AdminBookingsManagementScreen extends StatefulWidget {
  const AdminBookingsManagementScreen({super.key});

  @override
  State<AdminBookingsManagementScreen> createState() => _AdminBookingsManagementScreenState();
}

class _AdminBookingsManagementScreenState extends State<AdminBookingsManagementScreen> {
  String? _statusFilter;

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
      appBar: CustomAppBar(
        title: 'إدارة الحجوزات',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.adminAddBookingRoute),
            tooltip: 'إضافة حجز',
          ),
        ],
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
          final filteredBookings = _statusFilter == null
              ? bookings
              : bookings.where((b) => b.status == _statusFilter).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String?>(
                  value: _statusFilter,
                  hint: const Text('تصفية الحالة'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: 'pending_admin_approval', child: Text('قيد المراجعة')),
                    DropdownMenuItem(value: 'approved', child: Text('موافق عليه')),
                    DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                    DropdownMenuItem(value: 'deposit_paid', child: Text('دفع العربون')),
                    DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
                    DropdownMenuItem(value: 'scheduled', child: Text('مجدول')),
                  ],
                  onChanged: (val) {
                    setState(() => _statusFilter = val);
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('العميل')),
                        DataColumn(label: Text('الخدمة')),
                        DataColumn(label: Text('التاريخ')),
                        DataColumn(label: Text('الحالة')),
                      ],
                      rows: filteredBookings
                          .map(
                            (booking) => DataRow(
                              cells: [
                                DataCell(Text(booking.clientName)),
                                DataCell(Text(booking.serviceType)),
                                DataCell(Text(DateFormat('yyyy-MM-dd').format(booking.bookingDate))),
                                DataCell(Row(
                                  children: [
                                    Icon(
                                      _getBookingStatusIcon(booking.status),
                                      color: _getBookingStatusColor(booking.status),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(getBookingStatusLabel(booking.status)),
                                  ],
                                )),
                              ],
                              onSelectChanged: (_) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BookingDetailScreen(bookingId: booking.id),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
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