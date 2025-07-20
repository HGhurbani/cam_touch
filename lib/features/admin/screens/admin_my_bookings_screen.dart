// lib/features/admin/screens/admin_my_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../../core/utils/status_utils.dart';
import 'booking_detail_screen.dart';

class AdminMyBookingsScreen extends StatefulWidget {
  const AdminMyBookingsScreen({super.key});

  @override
  State<AdminMyBookingsScreen> createState() => _AdminMyBookingsScreenState();
}

class _AdminMyBookingsScreenState extends State<AdminMyBookingsScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _statusFilter = 'approved';
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _photographerController = TextEditingController();

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  @override
  void dispose() {
    _clientController.dispose();
    _photographerController.dispose();
    super.dispose();
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
      appBar: const CustomAppBar(title: 'حجوزاتي'),
      body: StreamBuilder<List<BookingModel>>(
        stream: firestoreService.getAllBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد حجوزات متاحة.'));
          }

          List<BookingModel> bookings = snapshot.data!;

          // Apply status filter
          if (_statusFilter != null) {
            bookings = bookings.where((b) => b.status == _statusFilter).toList();
          }
          if (_fromDate != null) {
            bookings = bookings
                .where((b) => !b.bookingDate.isBefore(_fromDate!))
                .toList();
          }
          if (_toDate != null) {
            bookings = bookings
                .where((b) => !b.bookingDate.isAfter(_toDate!))
                .toList();
          }
          final clientQuery = _clientController.text.trim();
          if (clientQuery.isNotEmpty) {
            bookings = bookings
                .where((b) =>
                    b.clientName.contains(clientQuery) ||
                    b.clientId.contains(clientQuery))
                .toList();
          }
          final photographerQuery = _photographerController.text.trim();
          if (photographerQuery.isNotEmpty) {
            bookings = bookings
                .where((b) =>
                    (b.photographerId ?? '').contains(photographerQuery) ||
                    (b.photographerIds ?? [])
                        .any((id) => id.contains(photographerQuery)))
                .toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: _pickFromDate,
                      child: Text(_fromDate == null
                          ? 'من تاريخ'
                          : DateFormat('yyyy-MM-dd').format(_fromDate!)),
                    ),
                    ElevatedButton(
                      onPressed: _pickToDate,
                      child: Text(_toDate == null
                          ? 'إلى تاريخ'
                          : DateFormat('yyyy-MM-dd').format(_toDate!)),
                    ),
                    DropdownButton<String?>(
                      value: _statusFilter,
                      hint: const Text('الحالة'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('الكل')),
                        DropdownMenuItem(value: 'approved', child: Text('موافق عليه')),
                        DropdownMenuItem(value: 'deposit_paid', child: Text('دفع العربون')),
                        DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
                        DropdownMenuItem(value: 'scheduled', child: Text('مجدول')),
                      ],
                      onChanged: (val) => setState(() => _statusFilter = val),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _clientController,
                        decoration: const InputDecoration(
                          labelText: 'البحث بالعميل',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _photographerController,
                        decoration: const InputDecoration(
                          labelText: 'بحث بالمصور',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'مسح الفلاتر',
                      onPressed: () {
                        setState(() {
                          _fromDate = null;
                          _toDate = null;
                          _statusFilter = 'approved';
                          _clientController.clear();
                          _photographerController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: bookings.isEmpty
                    ? const Center(child: Text('لا توجد نتائج مطابقة للفلترة.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('العميل')),
                              DataColumn(label: Text('الخدمة')),
                              DataColumn(label: Text('التاريخ')),
                              DataColumn(label: Text('الحالة')),
                            ],
                            rows: bookings
                                .map(
                                  (booking) => DataRow(
                                    cells: [
                                      DataCell(Text(booking.clientName)),
                                      DataCell(Text(booking.serviceType)),
                                      DataCell(Text(DateFormat('yyyy-MM-dd').format(booking.bookingDate))),
                                      DataCell(Text(getBookingStatusLabel(booking.status))),
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
}
