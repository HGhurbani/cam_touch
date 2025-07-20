// lib/features/photographer/screens/photographer_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/photographer_model.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_app_bar.dart';
import 'photographer_schedule_screen.dart'; // استيراد جديد لشاشة الجدول الزمني
import '../../../core/utils/status_utils.dart';

class PhotographerDashboardScreen extends StatefulWidget {
  const PhotographerDashboardScreen({super.key});

  @override
  State<PhotographerDashboardScreen> createState() => _PhotographerDashboardScreenState();
}

class _PhotographerDashboardScreenState extends State<PhotographerDashboardScreen>
    with SingleTickerProviderStateMixin {
  PhotographerModel? _photographerData;
  String? _errorMessage;
  UserModel? _photographerUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _loadPhotographerData();
    _loadUserData();
  }

  Future<void> _loadPhotographerData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (authService.currentUser != null) {
      _photographerData = await firestoreService.getPhotographerData(authService.currentUser!.uid);
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (authService.currentUser != null) {
      _photographerUser = await firestoreService.getUser(authService.currentUser!.uid);
      if (mounted) setState(() {});
    }
  }

  Future<void> _recordAttendance(EventModel event, String type) async {
    setState(() {
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);

    Position? position = await locationService.getCurrentLocation();
    if (position == null) {
      setState(() {
        _errorMessage = 'لا يمكن الحصول على الموقع. يرجى التأكد من تفعيل خدمات الموقع وإعطاء الإذن.';
      });
      return;
    }

    try {
      final attendanceRecord = AttendanceModel(
        id: firestoreService.randomDocumentId(),
        photographerId: authService.currentUser!.uid,
        eventId: event.id,
        type: type,
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        isLate: false,
        lateDeductionApplied: null,
      );

      String? recordId = await firestoreService.addAttendanceRecord(attendanceRecord);

      if (recordId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تسجيل ${type == 'check_in' ? 'الحضور' : 'الانصراف'} بنجاح!')),
        );
        _loadPhotographerData();
      } else {
        setState(() {
          _errorMessage = 'فشل تسجيل ${type == 'check_in' ? 'الحضور' : 'الانصراف'}.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: $e';
      });
    }
  }

  Future<bool> _hasCheckedIn(String eventId) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return false;

    final records = await firestoreService.getPhotographerAttendanceForEvent(
      authService.currentUser!.uid,
      eventId,
    ).first;

    return records.any((record) => record.type == 'check_in');
  }

  Future<bool> _hasCheckedOut(String eventId) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return false;

    final records = await firestoreService.getPhotographerAttendanceForEvent(
      authService.currentUser!.uid,
      eventId,
    ).first;

    return records.any((record) => record.type == 'check_out');
  }

  List<EventModel> _filterEvents(List<EventModel> events) {
    DateTime start;
    DateTime end;
    final now = DateTime.now();
    if (_tabController.index == 0) {
      // Today's events
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
    } else if (_tabController.index == 1) {
      // This week's events
      start = now.subtract(Duration(days: now.weekday - 1));
      end = start.add(const Duration(days: 7));
    } else {
      // This month's events
      start = DateTime(now.year, now.month);
      end = DateTime(now.year, now.month + 1);
    }

    return events.where((event) {
      final eventDate = event.eventDateTime;
      final eventEndApprox = eventDate.add(const Duration(hours: 4));
      if (eventEndApprox.isBefore(DateTime.now().subtract(const Duration(hours: 48)))) {
        return false;
      }
      return eventDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
          eventDate.isBefore(end);
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    if (authService.currentUser == null || authService.userRole != UserRole.photographer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const LoadingIndicator();
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'لوحة تحكم المصور',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
            tooltip: 'تسجيل الخروج',
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.photographerDeductionsRoute);
            },
            tooltip: 'تقارير الخصومات',
          ),
          IconButton( // زر جديد لجدول المصور
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PhotographerScheduleScreen()),
              );
            },
            tooltip: 'جدولي الزمني',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحبًا بك يا ${_photographerUser?.fullName ?? authService.currentUser?.email ?? 'مصور'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
              if (_photographerData != null) ...[
                Text(
                  'رصيدك الحالي: ${_photographerData!.balance.toStringAsFixed(2)} ريال يمني',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'إجمالي الخصومات: ${_photographerData!.totalDeductions.toStringAsFixed(2)} ريال يمني',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
            ],
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            const Text(
              'فعالياتي القادمة والحالية:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'اليوم'),
                Tab(text: 'الأسبوع'),
                Tab(text: 'الشهر'),
              ],
            ),
            Expanded(
              child: StreamBuilder<List<EventModel>>(
                stream: firestoreService.getPhotographerEvents(authService.currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator();
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('لا توجد فعاليات مجدولة لك حالياً.'));
                  }

                  final events = _filterEvents(snapshot.data!);
                  if (events.isEmpty) {
                    return const Center(child: Text('لا توجد فعاليات مجدولة لك حالياً.'));
                  }
                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الفعالية: ${event.title}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('التاريخ والوقت: ${DateFormat('yyyy-MM-dd HH:mm').format(event.eventDateTime.toLocal())}'),
                              Text('الموقع: ${event.location}'),
                              Text('الحالة: ${getEventStatusLabel(event.status)}'),
                              Text('خصم التأخير: ${event.lateDeductionAmount.toStringAsFixed(2)} ريال يمني'),
                              Text('مدة السماح: ${event.gracePeriodMinutes} دقيقة'),
                              const SizedBox(height: 10),
                              FutureBuilder<bool>(
                                future: _hasCheckedIn(event.id),
                                builder: (context, checkInSnapshot) {
                                  if (checkInSnapshot.connectionState == ConnectionState.waiting) {
                                    return const LoadingIndicator();
                                  }
                                  final hasCheckedIn = checkInSnapshot.data ?? false;
                                  return FutureBuilder<bool>(
                                    future: _hasCheckedOut(event.id),
                                    builder: (context, checkOutSnapshot) {
                                      if (checkOutSnapshot.connectionState == ConnectionState.waiting) {
                                        return const LoadingIndicator();
                                      }
                                      final hasCheckedOut = checkOutSnapshot.data ?? false;

                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Expanded(
                                            child: CustomButton(
                                              text: 'تسجيل حضور',
                                              onPressed: hasCheckedIn ? null : () => _recordAttendance(event, 'check_in'),
                                              color: hasCheckedIn ? Colors.grey : Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: CustomButton(
                                              text: 'تسجيل انصراف',
                                              onPressed: (hasCheckedIn && !hasCheckedOut) ? () => _recordAttendance(event, 'check_out') : null,
                                              color: (hasCheckedIn && !hasCheckedOut) ? Colors.red : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
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
            const SizedBox(height: 20),
            const Text(
              'حجوزاتك والمدفوعات:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<BookingModel>>(
                stream: firestoreService.getPhotographerBookings(authService.currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator();
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('لا توجد حجوزات حالياً.'));
                  }

                  final bookings = snapshot.data!;
                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final paid = booking.photographerPayments?[authService.currentUser!.uid] ?? 0.0;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text('${booking.serviceType} - ${DateFormat('yyyy-MM-dd').format(booking.bookingDate)}'),
                          subtitle: Text(
                            'المدفوع لك: ${paid.toStringAsFixed(2)} ريال يمني',
                            style: TextStyle(
                              color: paid > 0 ? Colors.green : null,
                              fontWeight: paid > 0 ? FontWeight.bold : null,
                            ),
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