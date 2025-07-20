import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/photographer_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../shared/widgets/custom_app_bar.dart';
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
      appBar: const CustomAppBar(title: 'تفاصيل المصور'),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_userData != null) ...[
                        Text(_userData!.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('البريد: ${_userData!.email}'),
                        Text('رقم الهاتف: ${_userData!.phoneNumber ?? '-'}'),
                        const SizedBox(height: 12),
                      ],
                      if (_photographerData != null) ...[
                        Text('التخصصات: ${_photographerData!.specialties.join(', ')}'),
                        Text('التقييم: ${_photographerData!.rating.toStringAsFixed(1)}'),
                        Text('عدد الحجوزات المكتملة: ${_photographerData!.totalBookings}'),
                        Text('الرصيد: ${_photographerData!.balance.toStringAsFixed(2)} ريال يمني'),
                        Text('إجمالي الخصومات: ${_photographerData!.totalDeductions.toStringAsFixed(2)} ريال يمني'),
                        const SizedBox(height: 20),
                      ],
                      const Text('الفعاليات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      StreamBuilder<List<EventModel>>(
                        stream: firestoreService.getPhotographerEvents(widget.photographerId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const LoadingIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text('خطأ: ${snapshot.error}');
                          }
                          final events = snapshot.data;
                          if (events == null || events.isEmpty) {
                            return const Text('لا توجد فعاليات.');
                          }
                          return Column(
                            children: events.map((e) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6.0),
                                child: ListTile(
                                  title: Text(e.title),
                                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(e.eventDateTime.toLocal())),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('الحجوزات والمدفوعات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      StreamBuilder<List<BookingModel>>(
                        stream: firestoreService.getPhotographerBookings(widget.photographerId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const LoadingIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text('خطأ: ${snapshot.error}');
                          }
                          final bookings = snapshot.data;
                          if (bookings == null || bookings.isEmpty) {
                            return const Text('لا توجد حجوزات.');
                          }
                          return Column(
                            children: bookings.map((b) {
                              final paid = b.photographerPayments?[widget.photographerId] ?? 0.0;
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6.0),
                                child: ListTile(
                                  title: Text('${b.serviceType} - ${DateFormat('yyyy-MM-dd').format(b.bookingDate)}'),
                                  subtitle: Text('المدفوع: ${paid.toStringAsFixed(2)} ريال يمني'),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
