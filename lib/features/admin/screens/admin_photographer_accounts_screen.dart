import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../../core/utils/status_utils.dart';

class AdminPhotographerAccountsScreen extends StatefulWidget {
  const AdminPhotographerAccountsScreen({super.key});

  @override
  State<AdminPhotographerAccountsScreen> createState() => _AdminPhotographerAccountsScreenState();
}

class _AdminPhotographerAccountsScreenState extends State<AdminPhotographerAccountsScreen> {
  String _search = '';

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
      appBar: const CustomAppBar(title: 'إدارة حسابات المصورين'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'بحث',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: firestoreService.getAllBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد حجوزات'));
                }

                final bookings = snapshot.data!
                    .where((b) => b.status == 'completed')
                    .where((b) =>
                        (b.photographerIds != null && b.photographerIds!.isNotEmpty) ||
                        b.photographerId != null)
                    .where((b) {
                      if (_search.isEmpty) return true;
                      final q = _search.toLowerCase();
                      return b.clientName.toLowerCase().contains(q) ||
                          b.serviceType.toLowerCase().contains(q);
                    }).toList();

                if (bookings.isEmpty) {
                  return const Center(child: Text('لا توجد نتائج'));
                }

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
                              'الخدمة: ${booking.serviceType} - ${DateFormat('yyyy-MM-dd').format(booking.bookingDate)} (${getBookingStatusLabel(booking.status)})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            for (final pid in booking.photographerIds ??
                                (booking.photographerId != null
                                    ? [booking.photographerId!]
                                    : <String>[]))
                              FutureBuilder<UserModel?>(
                                future: firestoreService.getUser(pid),
                                builder: (context, userSnapshot) {
                                  final name = userSnapshot.data?.fullName ?? pid;
                                  final paid = booking.photographerPayments?[pid] ?? 0.0;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('المصور: $name'),
                                    subtitle: Text('المدفوع: ${paid.toStringAsFixed(2)} ريال يمني'),
                                    trailing: TextButton(
                                      onPressed: () async {
                                        final controller = TextEditingController();
                                        final amount = await showDialog<double>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('إدخال المبلغ'),
                                            content: TextField(
                                              controller: controller,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(labelText: 'المبلغ'),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('إلغاء'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  final val = double.tryParse(controller.text);
                                                  Navigator.pop(context, val);
                                                },
                                                child: const Text('حفظ'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (amount != null) {
                                          await firestoreService.recordPhotographerPayment(booking.id, pid, amount);
                                        }
                                      },
                                      child: const Text('دفع'),
                                    ),
                                  );
                                },
                              ),
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
    );
  }
}
