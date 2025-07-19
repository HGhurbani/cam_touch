// lib/features/admin/screens/reports/client_financial_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // لفتح رابط الفاتورة

import '../../../../core/models/booking_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../../routes/app_router.dart';

class ClientFinancialReportScreen extends StatelessWidget {
  const ClientFinancialReportScreen({super.key});

  // دالة لفتح رابط URL
  void _launchURL(String url) async {
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
        title: const Text('تقارير العملاء والدفعات'),
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
            return const Center(child: Text('لا توجد حجوزات لعرض تقاريرها.'));
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الحجز: ${booking.serviceType} - ${DateFormat('yyyy-MM-dd').format(booking.bookingDate)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      FutureBuilder<UserModel?>(
                        future: firestoreService.getUser(booking.clientId),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.hasData && userSnapshot.data != null) {
                            return Text('العميل: ${userSnapshot.data!.fullName} (${userSnapshot.data!.email})');
                          }
                          return Text('العميل ID: ${booking.clientId}');
                        },
                      ),
                      Text('الحالة: ${booking.status}'),
                      Text('التكلفة المقدرة: \$${booking.estimatedCost.toStringAsFixed(2)}'),
                      if (booking.depositAmount != null)
                        Text('العربون المدفوع: \$${booking.depositAmount!.toStringAsFixed(2)}'),
                      if (booking.invoiceUrl != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('عرض الفاتورة'),
                            onPressed: () => _launchURL(booking.invoiceUrl!),
                          ),
                        ),
                      if (booking.paymentProofUrl != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.attach_file),
                            label: const Text('عرض إثبات الدفع'),
                            onPressed: () => _launchURL(booking.paymentProofUrl!),
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