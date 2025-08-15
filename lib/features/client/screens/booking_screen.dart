// lib/features/client/screens/booking_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_app_bar.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedServiceType;
  double _estimatedCost = 0.0;

  bool _isLoading = false;
  String? _errorMessage;

  // قائمة بأنواع الخدمات
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
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
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'حجز جلسة تصوير',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'جاري إنشاء الحجز...')
          : SingleChildScrollView(
              padding: AppStyles.paddingLarge,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildServiceTypeSection(),
                    const SizedBox(height: 24),
                    _buildDateTimeSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorMessage(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: AppStyles.paddingLarge,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
        boxShadow: AppStyles.shadowMedium,
      ),
      child: Column(
        children: [
          Container(
            padding: AppStyles.paddingMedium,
            decoration: BoxDecoration(
              color: AppColors.whiteWithOpacity(0.15),
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'احجز جلسة التصوير الخاصة بك',
            style: AppStyles.headline4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'اختر نوع الخدمة والتاريخ والوقت المناسبين',
            style: AppStyles.body2.copyWith(
              color: AppColors.whiteWithOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الخدمة',
          style: AppStyles.headline4.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _serviceTypes.length,
          itemBuilder: (context, index) {
            final serviceType = _serviceTypes[index];
            final isSelected = _selectedServiceType == serviceType;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedServiceType = serviceType;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.primaryWithOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? AppStyles.shadowMedium : AppStyles.shadowSmall,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getServiceIcon(serviceType),
                      color: isSelected ? Colors.white : AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      serviceType,
                      style: AppStyles.body2.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'تصوير فعاليات':
        return Icons.event_rounded;
      case 'تصوير منتجات':
        return Icons.inventory_2_rounded;
      case 'جلسات شخصية':
        return Icons.person_rounded;
      case 'تصوير فوتوغرافي تجاري':
        return Icons.business_rounded;
      case 'تصوير عقاري':
        return Icons.home_rounded;
      case 'تصوير جوي':
        return Icons.flight_rounded;
      default:
        return Icons.camera_alt_rounded;
    }
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التاريخ والوقت',
          style: AppStyles.headline4.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimePicker(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: AppStyles.paddingMedium,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          border: Border.all(color: AppColors.primaryWithOpacity(0.2)),
          boxShadow: AppStyles.shadowSmall,
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDate != null
                  ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                  : 'اختر التاريخ',
              style: AppStyles.body2.copyWith(
                color: _selectedDate != null ? AppColors.textPrimary : AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: AppStyles.paddingMedium,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          border: Border.all(color: AppColors.primaryWithOpacity(0.2)),
          boxShadow: AppStyles.shadowSmall,
        ),
        child: Column(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'اختر الوقت',
              style: AppStyles.body2.copyWith(
                color: _selectedTime != null ? AppColors.textPrimary : AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'موقع التصوير',
          style: AppStyles.headline4.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'أدخل عنوان موقع التصوير',
            prefixIcon: const Icon(Icons.location_on_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال موقع التصوير';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'إنشاء الحجز',
        onPressed: _canSubmit() ? _submitBooking : null,
        buttonType: ButtonType.primary,
        icon: Icons.check_rounded,
        height: 56,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: AppStyles.paddingMedium,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppStyles.body2.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    return _selectedServiceType != null &&
           _selectedDate != null &&
           _selectedTime != null &&
           _locationController.text.isNotEmpty;
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      if (authService.currentUser == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      // دمج التاريخ والوقت
      final DateTime bookingDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final booking = BookingModel(
        id: firestoreService.randomDocumentId(),
        clientId: authService.currentUser!.uid,
        photographerId: null,
        clientName: authService.currentUser?.displayName ?? 'عميل',
        clientEmail: authService.currentUser?.email ?? '',
        bookingDate: bookingDateTime,
        bookingTime: _selectedTime!.format(context),
        location: _locationController.text,
        serviceType: _selectedServiceType!,
        estimatedCost: _estimatedCost,
        status: 'pending_admin_approval',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      await firestoreService.addBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إنشاء الحجز بنجاح!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}