// lib/features/photographer/screens/photographer_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/location_service.dart';
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

class _PhotographerDashboardScreenState extends State<PhotographerDashboardScreen> {
  PhotographerModel? _photographerData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPhotographerData();
  }

  Future<void> _loadPhotographerData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (authService.currentUser != null) {
      _photographerData = await firestoreService.getPhotographerData(authService.currentUser!.uid);
      setState(() {});
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
              'مرحبًا بك يا ${authService.currentUser?.email ?? 'مصور'}!',
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
              'فعالياتي القادمة والحالية (ملخص):',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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

                  final events = snapshot.data!;
                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final eventEndApprox = event.eventDateTime.add(const Duration(hours: 4));
                      if (eventEndApprox.isBefore(DateTime.now().subtract(const Duration(hours: 48)))) {
                        return const SizedBox.shrink();
                      }

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
          ],
        ),
      ),
    );
  }
}