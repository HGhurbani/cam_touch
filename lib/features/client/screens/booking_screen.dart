// lib/features/client/screens/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ والوقت

import '../../../core/models/booking_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedServiceType;
  double _estimatedCost = 0.0; // يمكن حسابها ديناميكيًا لاحقًا

  bool _isLoading = false;
  String? _errorMessage;

  // قائمة بأنواع الخدمات (يمكن جلبها من Firestore في تطبيق حقيقي)
  final List<String> _serviceTypes = [
    'تصوير فعاليات',
    'تصوير منتجات',
    'جلسات شخصية',
    'تصوير فوتوغرافي تجاري',
    'تصوير عقاري',
    'تصوير جوي'
  ];

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)), // سنة مقدماً
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // يمكن توسيعها لتشمل فترات زمنية متاحة من المصورين
  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked.format(context); // تنسيق الوقت حسب لغة الجهاز
      });
    }
  }

  void _calculateEstimatedCost() {
    // منطق حساب التكلفة التقديرية بناءً على نوع الخدمة، المدة، إلخ.
    // حالياً، سنضع قيمة عشوائية لأغراض التوضيح
    if (_selectedServiceType != null) {
      setState(() {
        // مثال بسيط
        switch (_selectedServiceType) {
          case 'تصوير فعاليات':
            _estimatedCost = 500.0;
            break;
          case 'تصوير منتجات':
            _estimatedCost = 300.0;
            break;
          case 'جلسات شخصية':
            _estimatedCost = 200.0;
            break;
          default:
            _estimatedCost = 150.0;
            break;
        }
      });
    }
  }

  Future<void> _submitBookingRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        setState(() => _errorMessage = 'الرجاء اختيار تاريخ الحجز.');
        return;
      }
      if (_selectedTime == null) {
        setState(() => _errorMessage = 'الرجاء اختيار وقت الحجز.');
        return;
      }
      if (_selectedServiceType == null) {
        setState(() => _errorMessage = 'الرجاء اختيار نوع الخدمة.');
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      if (authService.currentUser == null) {
        setState(() => _errorMessage = 'لا يوجد مستخدم مسجل الدخول.');
        _isLoading = false;
        return;
      }

      // الحصول على بيانات العميل من Firestore لتعبئة الاسم والبريد الإلكتروني
      // يمكن تحسين هذا بجلب بيانات العميل مرة واحدة وتخزينها
      final clientUser = await firestoreService.getUser(authService.currentUser!.uid);
      if (clientUser == null) {
        setState(() => _errorMessage = 'لم يتم العثور على بيانات العميل.');
        _isLoading = false;
        return;
      }

      final newBooking = BookingModel(
        id: firestoreService.randomDocumentId(), // هذا يتطلب دالة جديدة في FirestoreService
        clientId: authService.currentUser!.uid,
        clientName: clientUser.fullName,
        clientEmail: clientUser.email,
        bookingDate: _selectedDate!,
        bookingTime: _selectedTime!,
        location: _locationController.text.trim(),
        serviceType: _selectedServiceType!,
        estimatedCost: _estimatedCost,
        status: 'pending_admin_approval', // الحالة الأولية
        createdAt: Timestamp.now(), // Firestore timestamp
      );

      String? bookingId = await firestoreService.addBooking(newBooking);

      setState(() {
        _isLoading = false;
      });

      if (bookingId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب الحجز بنجاح! سيتم مراجعته من قبل المدير.')),
        );
        Navigator.of(context).pop(); // العودة إلى لوحة تحكم العميل
      } else {
        setState(() => _errorMessage = 'فشل إرسال طلب الحجز. الرجاء المحاولة مرة أخرى.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجز جلسة تصوير جديدة'),
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
              // حقل اختيار التاريخ
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'اختر تاريخ الجلسة'
                      : 'تاريخ الجلسة: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              // حقل اختيار الوقت
              ListTile(
                title: Text(
                  _selectedTime == null
                      ? 'اختر وقت الجلسة'
                      : 'وقت الجلسة: $_selectedTime',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              // حقل نوع الخدمة
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: const InputDecoration(
                  labelText: 'نوع الخدمة المطلوبة',
                  border: OutlineInputBorder(),
                ),
                items: _serviceTypes.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedServiceType = newValue;
                    _calculateEstimatedCost(); // إعادة حساب التكلفة
                  });
                },
                validator: (value) =>
                value == null ? 'الرجاء اختيار نوع الخدمة' : null,
              ),
              const SizedBox(height: 16),
              // حقل الموقع
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    labelText: 'الموقع/العنوان',
                    border: OutlineInputBorder(),
                    hintText: 'مثال: قاعة الأفراح الملكية، حي الفل'
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال موقع الجلسة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // عرض التكلفة التقديرية
              Text(
                'التكلفة التقديرية: \$${_estimatedCost.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
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
                text: 'إرسال طلب الحجز',
                onPressed: _submitBookingRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}