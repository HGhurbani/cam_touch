// lib/features/admin/screens/admin_events_scheduling_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // لاستخدام Timestamp

import '../../../core/models/event_model.dart';
import '../../../core/models/photographer_model.dart';
import '../../../core/models/booking_model.dart'; // لاسترداد تفاصيل الحجز
import '../../../core/models/user_model.dart'; // لاسم المصور
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';

class AdminEventsSchedulingScreen extends StatefulWidget {
  const AdminEventsSchedulingScreen({super.key});

  @override
  State<AdminEventsSchedulingScreen> createState() => _AdminEventsSchedulingScreenState();
}

class _AdminEventsSchedulingScreenState extends State<AdminEventsSchedulingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _lateDeductionAmountController = TextEditingController();
  final TextEditingController _gracePeriodMinutesController = TextEditingController();


  DateTime? _selectedEventDate;
  TimeOfDay? _selectedEventTime;
  String? _selectedBookingId; // لربط الفعالية بحجز موجود
  String? _selectedPhotographerId; // لتعيين المصور

  bool _isLoading = false;
  String? _errorMessage;

  List<BookingModel> _availableBookings = []; // الحجوزات المتاحة للربط
  List<PhotographerModel> _allPhotographers = []; // قائمة بجميع المصورين

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    try {
      // جلب جميع الحجوزات الموافق عليها والتي لم يتم ربطها بفعالية أو مصور بعد
      // هذا الشرط يمكن أن يكون أكثر تعقيدًا بناءً على متطلبات العمل
      _availableBookings = (await firestoreService.getAllBookings().first)
          .where((b) => b.status == 'approved' && b.photographerId == null)
          .toList();
      _allPhotographers = (await firestoreService.getAllPhotographers().first);
      _lateDeductionAmountController.text = '50.0'; // قيمة افتراضية للخصم
      _gracePeriodMinutesController.text = '10'; // قيمة افتراضية لمدة السماح
    } catch (e) {
      _errorMessage = 'خطأ في تحميل البيانات الأولية: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _lateDeductionAmountController.dispose();
    _gracePeriodMinutesController.dispose();
    super.dispose();
  }

  Future<void> _pickEventDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // سنتين مقدماً
    );
    if (picked != null && picked != _selectedEventDate) {
      setState(() {
        _selectedEventDate = picked;
      });
    }
  }

  Future<void> _pickEventTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEventTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedEventTime = picked;
      });
    }
  }

  Future<void> _addEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedEventDate == null || _selectedEventTime == null) {
        setState(() => _errorMessage = 'الرجاء اختيار تاريخ ووقت الفعالية.');
        return;
      }
      if (_selectedBookingId == null) {
        setState(() => _errorMessage = 'الرجاء ربط الفعالية بحجز موجود.');
        return;
      }
      if (_selectedPhotographerId == null) {
        setState(() => _errorMessage = 'الرجاء تعيين مصور للفعالية.');
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      // دمج التاريخ والوقت
      final DateTime eventDateTime = DateTime(
        _selectedEventDate!.year,
        _selectedEventDate!.month,
        _selectedEventDate!.day,
        _selectedEventTime!.hour,
        _selectedEventTime!.minute,
      );

      final newEvent = EventModel(
        id: firestoreService.randomDocumentId(),
        bookingId: _selectedBookingId!,
        assignedPhotographerId: _selectedPhotographerId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDateTime: eventDateTime,
        location: _locationController.text.trim(),
        lateDeductionAmount: double.tryParse(_lateDeductionAmountController.text) ?? 0.0,
        gracePeriodMinutes: int.tryParse(_gracePeriodMinutesController.text) ?? 10,
        createdAt: Timestamp.now(),
      );

      String? eventId = await firestoreService.addEvent(newEvent);

      if (eventId != null) {
        // تحديث حالة الحجز في Firestore لربطه بالفعالية وتعيين المصور
        await firestoreService.updateBooking(
          _selectedBookingId!,
          {
            'status': 'scheduled', // تغيير حالة الحجز إلى "مجدولة"
            'photographerId': _selectedPhotographerId, // تعيين المصور للحجز
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الفعالية وتعيين المصور بنجاح!')),
        );
        Navigator.of(context).pop(); // العودة إلى لوحة تحكم المدير
      } else {
        setState(() => _errorMessage = 'فشل إضافة الفعالية. الرجاء المحاولة مرة أخرى.');
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (authService.currentUser == null || authService.userRole != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const LoadingIndicator();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('جدولة الفعاليات'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // حقل اختيار الحجز لربط الفعالية
              DropdownButtonFormField<String>(
                value: _selectedBookingId,
                decoration: const InputDecoration(
                  labelText: 'ربط بحجز موجود (لم يُسند بعد)',
                  border: OutlineInputBorder(),
                ),
                items: _availableBookings.map((booking) {
                  return DropdownMenuItem(
                    value: booking.id,
                    child: Text('${booking.clientName} - ${booking.serviceType} - ${DateFormat('yyyy-MM-dd').format(booking.bookingDate)}'),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedBookingId = newValue;
                  });
                },
                validator: (value) => value == null ? 'الرجاء اختيار حجز لربط الفعالية.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'عنوان الفعالية',
                    border: OutlineInputBorder(),
                    hintText: 'مثال: تصوير زفاف عائلة الأحمد'
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال عنوان الفعالية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف الفعالية (اختياري)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedEventDate == null
                      ? 'اختر تاريخ الفعالية'
                      : 'تاريخ الفعالية: ${DateFormat('yyyy-MM-dd').format(_selectedEventDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickEventDate,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedEventTime == null
                      ? 'اختر وقت الفعالية'
                      : 'وقت الفعالية: ${_selectedEventTime!.format(context)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _pickEventTime,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    labelText: 'موقع الفعالية',
                    border: OutlineInputBorder(),
                    hintText: 'مثال: قاعة النور، شارع الفرسان'
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال موقع الفعالية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lateDeductionAmountController,
                decoration: const InputDecoration(
                    labelText: 'مبلغ الخصم عند التأخير',
                    border: OutlineInputBorder(),
                    hintText: 'مثال: 50.00'
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال مبلغ الخصم (0 إذا لا يوجد)';
                  }
                  if (double.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صالح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gracePeriodMinutesController,
                decoration: const InputDecoration(
                    labelText: 'مدة السماح بالتأخير (دقائق)',
                    border: OutlineInputBorder(),
                    hintText: 'مثال: 10'
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال مدة السماح';
                  }
                  if (int.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // اختيار المصور لتعيينه للفعالية
              DropdownButtonFormField<String>(
                value: _selectedPhotographerId,
                decoration: const InputDecoration(
                  labelText: 'تعيين مصور للفعالية',
                  border: OutlineInputBorder(),
                ),
                items: _allPhotographers.map((photographer) {
                  return DropdownMenuItem(
                    value: photographer.uid,
                    child: FutureBuilder<UserModel?>(
                      future: firestoreService.getUser(photographer.uid),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.hasData && userSnapshot.data != null) {
                          return Text(userSnapshot.data!.fullName);
                        }
                        return Text('المصور ID: ${photographer.uid}');
                      },
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedPhotographerId = newValue;
                  });
                },
                validator: (value) => value == null ? 'الرجاء تعيين مصور.' : null,
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              CustomButton(
                text: 'إضافة فعالية',
                onPressed: () => _addEvent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}