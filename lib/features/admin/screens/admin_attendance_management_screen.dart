// lib/features/admin/screens/admin_attendance_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/attendance_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/event_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_indicator.dart';

class AdminAttendanceManagementScreen extends StatefulWidget {
  const AdminAttendanceManagementScreen({super.key});

  @override
  State<AdminAttendanceManagementScreen> createState() =>
      _AdminAttendanceManagementScreenState();
}

class _AdminAttendanceManagementScreenState
    extends State<AdminAttendanceManagementScreen> {
  DateTime? _selectedDate;
  String? _selectedPhotographerId;

  void _launchGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
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
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const LoadingIndicator();
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'إدارة الحضور والغياب'),
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

          return StreamBuilder<List<AttendanceModel>>(
            stream: firestoreService.getAllAttendanceRecords(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }
              if (snapshot.hasError) {
                return Center(child: Text('خطأ: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('لا توجد سجلات حضور/انصراف.'));
              }

              List<AttendanceModel> records = snapshot.data!;
              if (_selectedPhotographerId != null) {
                records = records
                    .where((r) => r.photographerId == _selectedPhotographerId)
                    .toList();
              }
              if (_selectedDate != null) {
                records = records
                    .where((r) =>
                        r.timestamp.year == _selectedDate!.year &&
                        r.timestamp.month == _selectedDate!.month &&
                        r.timestamp.day == _selectedDate!.day)
                    .toList();
              }

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
                            onChanged: (val) {
                              setState(() => _selectedPhotographerId = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                hintText: 'التاريخ',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? 'الكل'
                                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'مسح الفلاتر',
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                              _selectedPhotographerId = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<UserModel?>(
                                  future: firestoreService.getUser(record.photographerId),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.hasData && userSnapshot.data != null) {
                                      return Text(
                                        'المصور: ${userSnapshot.data!.fullName}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                FutureBuilder<EventModel?>(
                                  future: firestoreService.getEvent(record.eventId),
                                  builder: (context, eventSnapshot) {
                                    if (eventSnapshot.hasData && eventSnapshot.data != null) {
                                      return Text('الفعالية: ${eventSnapshot.data!.title}');
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                Text('النوع: ${record.type == 'check_in' ? 'حضور' : 'انصراف'}'),
                                Text('الوقت: ${DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp)}'),
                                Text('الإحداثيات: ${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}'),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.map),
                                    label: const Text('عرض الموقع على الخريطة'),
                                    onPressed: () => _launchGoogleMaps(record.latitude, record.longitude),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
