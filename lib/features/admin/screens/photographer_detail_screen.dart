// lib/features/admin/screens/photographer_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/photographer_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/firestore_service.dart';
// Removed CustomAppBar as it's being replaced with a custom one in this file
import '../../shared/widgets/loading_indicator.dart';

class PhotographerDetailScreen extends StatefulWidget {
  final String photographerId;
  const PhotographerDetailScreen({super.key, required this.photographerId});

  @override
  State<PhotographerDetailScreen> createState() => _PhotographerDetailScreenState();
}

class _PhotographerDetailScreenState extends State<PhotographerDetailScreen> {
  PhotographerModel? _photographerData;
  UserModel? _userData;
  bool _loading = true;
  String? _error;

  // الألوان الأساسية
  static const Color primaryColor = Color(0xFF024650);
  static const Color accentColor = Color(0xFFFF9403);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    try {
      _userData = await firestoreService.getUser(widget.photographerId);
      _photographerData = await firestoreService.getPhotographerData(widget.photographerId);
    } catch (e) {
      _error = 'خطأ في جلب البيانات: $e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return Scaffold(
      backgroundColor: lightGray, // Consistent background color
      appBar: _buildAppBar(context),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
          ? _buildErrorState(_error!)
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotographerInfoCard(),
            const SizedBox(height: 20),
            _buildSectionTitle('الحجوزات والمدفوعات'),
            _buildBookingsList(firestoreService),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      title: const Text(
        'تفاصيل المصور',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        // Add any relevant actions here, e.g., edit photographer details
        // IconButton(
        //   icon: const Icon(Icons.edit),
        //   onPressed: () {
        //     // Navigate to edit screen
        //   },
        //   tooltip: 'تعديل المصور',
        // ),
      ],
    );
  }

  Widget _buildPhotographerInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero, // Remove default card margin
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor,
                  radius: 30,
                  child: Text(
                    _userData?.fullName.isNotEmpty == true ? _userData!.fullName[0].toUpperCase() : 'م',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userData?.fullName ?? 'مصور غير معروف',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        _userData?.email ?? 'لا يوجد بريد إلكتروني',
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                      if (_userData?.phoneNumber != null)
                        Text(
                          _userData!.phoneNumber!,
                          style: TextStyle(fontSize: 14, color: textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1, color: Colors.black12),
            _buildInfoRow(Icons.money_off_csred_outlined, 'إجمالي الخصومات',
                '${_photographerData?.totalDeductions.toStringAsFixed(2) ?? '0.00'} ريال يمني'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.account_balance_wallet_outlined, 'الرصيد الإجمالي',
                '${_photographerData?.balance.toStringAsFixed(2) ?? '0.00'} ريال يمني'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildEventsList(FirestoreService firestoreService) {
    return StreamBuilder<List<EventModel>>(
      stream: firestoreService.getPhotographerEvents(widget.photographerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return _buildErrorState('خطأ في جلب الفعاليات: ${snapshot.error}');
        }
        final events = snapshot.data;
        if (events == null || events.isEmpty) {
          return _buildEmptyListState('لا توجد فعاليات مجدولة لهذا المصور.');
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final e = events[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.1),
                  child: Icon(Icons.event_note, color: accentColor),
                ),
                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('yyyy-MM-dd HH:mm').format(e.eventDateTime.toLocal())),
                    Text('الموقع: ${e.location}'),
                  ],
                ),
                trailing: Text(
                  'خصم: ${e.lateDeductionAmount.toStringAsFixed(2)} ر.ي',
                  style: TextStyle(color: errorColor, fontSize: 12),
                ),
                onTap: () {
                  // Navigate to event detail if needed
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookingsList(FirestoreService firestoreService) {
    return StreamBuilder<List<BookingModel>>(
      stream: firestoreService.getPhotographerBookings(widget.photographerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return _buildErrorState('خطأ في جلب الحجوزات: ${snapshot.error}');
        }
        final bookings = snapshot.data;
        if (bookings == null || bookings.isEmpty) {
          return _buildEmptyListState('لا توجد حجوزات لهذا المصور.');
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final b = bookings[index];
            final paid = b.photographerPayments?[widget.photographerId] ?? 0.0;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.photo_album, color: primaryColor),
                ),
                title: Text('${b.serviceType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('بتاريخ: ${DateFormat('yyyy-MM-dd').format(b.bookingDate)}'),
                trailing: Text(
                  'المدفوع: ${paid.toStringAsFixed(2)} ر.ي',
                  style: TextStyle(color: successColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  // Navigate to booking detail if needed
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyListState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 18,
                color: errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}