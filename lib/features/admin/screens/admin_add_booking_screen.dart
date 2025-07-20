import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';

class AdminAddBookingScreen extends StatefulWidget {
  const AdminAddBookingScreen({super.key});

  @override
  State<AdminAddBookingScreen> createState() => _AdminAddBookingScreenState();
}

class _AdminAddBookingScreenState extends State<AdminAddBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedServiceType;
  String? _selectedClientId;
  double _estimatedCost = 0.0;

  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> _clients = [];

  final List<String> _serviceTypes = [
    'تصوير فعاليات',
    'تصوير منتجات',
    'جلسات شخصية',
    'تصوير فوتوغرافي تجاري',
    'تصوير عقاري',
    'تصوير جوي'
  ];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _clients = await firestoreService.getAllClients().first;
    setState(() {});
  }

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
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked.format(context);
      });
    }
  }

  void _calculateEstimatedCost() {
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
    }
  }

  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedClientId == null) {
        setState(() => _errorMessage = 'الرجاء اختيار العميل.');
        return;
      }
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

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final client = _clients.firstWhere((c) => c.uid == _selectedClientId);
      final booking = BookingModel(
        id: '',
        clientId: client.uid,
        clientName: client.fullName,
        clientEmail: client.email,
        photographerId: null,
        bookingDate: _selectedDate!,
        bookingTime: _selectedTime!,
        location: _locationController.text,
        serviceType: _selectedServiceType!,
        estimatedCost: _estimatedCost,
        status: 'pending_admin_approval',
        depositAmount: null,
        paymentProofUrl: null,
        invoiceUrl: null,
        createdAt: Timestamp.now(),
        updatedAt: null,
      );

      String? bookingId = await firestoreService.addBooking(booking);

      setState(() {
        _isLoading = false;
      });

      if (bookingId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الحجز بنجاح.')),
        );
        Navigator.of(context).pop();
      } else {
        setState(() => _errorMessage = 'فشل إضافة الحجز.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'إضافة حجز'),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedClientId,
                      decoration: const InputDecoration(
                        labelText: 'اختر العميل',
                        border: OutlineInputBorder(),
                      ),
                      items: _clients
                          .map((client) => DropdownMenuItem(
                                value: client.uid,
                                child: Text(client.fullName),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedClientId = val;
                        });
                      },
                      validator: (value) => value == null ? 'الرجاء اختيار العميل' : null,
                    ),
                    const SizedBox(height: 16),
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
                    DropdownButtonFormField<String>(
                      value: _selectedServiceType,
                      decoration: const InputDecoration(
                        labelText: 'نوع الخدمة المطلوبة',
                        border: OutlineInputBorder(),
                      ),
                      items: _serviceTypes
                          .map((service) => DropdownMenuItem(
                                value: service,
                                child: Text(service),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedServiceType = val;
                          _calculateEstimatedCost();
                        });
                      },
                      validator: (value) => value == null ? 'الرجاء اختيار نوع الخدمة' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'الموقع/العنوان',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال موقع الجلسة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
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
                      text: 'إضافة الحجز',
                      onPressed: _submitBooking,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
