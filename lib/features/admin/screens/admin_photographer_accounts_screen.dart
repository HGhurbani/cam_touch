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
  DateTime? _selectedDate;
  String? _selectedPhotographerId;

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

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
      body: StreamBuilder<List<UserModel>>( 
        stream: firestoreService.getAllPhotographerUsers(),
        builder: (context, photographersSnapshot) {
          if (photographersSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (photographersSnapshot.hasError) {
            return Center(child: Text('خطأ: ${photographersSnapshot.error}'));
          }

          final photographers = photographersSnapshot.data ?? [];

          return Column(
            children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: _selectedPhotographerId,
                    hint: const Text('المصور'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('الكل')),
                      ...photographers.map(
                        (p) => DropdownMenuItem(
                          value: p.uid,
                          child: Text(p.fullName),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedPhotographerId = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    title: Text(
                      _selectedDate == null
                          ? 'اختر التاريخ'
                          : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                    ),
                    leading: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                ),
                if (_selectedDate != null || _selectedPhotographerId != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _selectedDate = null;
                      _selectedPhotographerId = null;
                    }),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: _selectedDate == null
                  ? firestoreService.getAllBookings()
                  : firestoreService.getBookingsByDate(_selectedDate!),
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
                      if (_selectedPhotographerId == null) return true;
                      final ids = b.photographerIds ??
                          (b.photographerId != null ? [b.photographerId!] : <String>[]);
                      return ids.contains(_selectedPhotographerId);
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
                            const SizedBox(height: 4),
                            Text('العميل: ${booking.clientName} (${booking.clientEmail})'),
                            Text('الموقع: ${booking.location}'),
                            Text('الوقت: ${booking.bookingTime}'),
                            Text('التكلفة: ${booking.estimatedCost.toStringAsFixed(2)} ريال يمني'),
                            Text('المدفوع: ${booking.paidAmount.toStringAsFixed(2)} ريال يمني'),
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
                                    subtitle: Text(
                                      'المدفوع: ${paid.toStringAsFixed(2)} ريال يمني',
                                      style: paid > 0
                                          ? const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            )
                                          : null,
                                    ),
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
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('تم تسجيل الدفع')),
                                            );
                                          }
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
      );
    },
  ),
);
  }
}
