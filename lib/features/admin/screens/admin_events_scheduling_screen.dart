// lib/features/admin/screens/admin_events_scheduling_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // لاستخدام Timestamp

import '../../../core/models/event_model.dart';

import '../../../core/models/booking_model.dart'; // لاسترداد تفاصيل الحجز
import '../../../core/models/user_model.dart'; // لاسم المصور
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';
// Removed CustomAppBar as it's being replaced with a custom one in this file

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
  List<String> _selectedPhotographerIds = []; // لتعيين أكثر من مصور

  bool _isLoading = false;
  String? _errorMessage;

  List<BookingModel> _availableBookings = []; // الحجوزات المتاحة للربط
  List<UserModel> _allPhotographers = []; // قائمة بجميع المصورين

  // الألوان الأساسية
  static const Color primaryColor = Color(0xFF024650);
  static const Color accentColor = Color(0xFFFF9403);
  static const Color lightGray = Color(0xFFF5F5F5); // Added for consistency

  Future<void> _selectPhotographers() async {
    final List<String> tempSelected = List.from(_selectedPhotographerIds);
    await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
          title: const Text('اختر المصورين', style: TextStyle(color: primaryColor)),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                if (_allPhotographers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا يوجد مصورون متاحون',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'يجب إضافة مصورين أولاً من صفحة إدارة المصورين',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView(
                  children: _allPhotographers.map((photographer) {
                    final isChecked = tempSelected.contains(photographer.uid);
                    return CheckboxListTile(
                      value: isChecked,
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            tempSelected.add(photographer.uid);
                          } else {
                            tempSelected.remove(photographer.uid);
                          }
                        });
                      },
                      title: Text(photographer.fullName),
                      activeColor: accentColor, // Checkbox color
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: primaryColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempSelected),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('موافق'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null) {
        setState(() {
          _selectedPhotographerIds = List<String>.from(value);
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    try {
      _availableBookings = (await firestoreService.getAllBookings().first)
          .where((b) =>
      b.status == 'approved' &&
          (b.photographerIds == null || b.photographerIds!.isEmpty))
          .toList();
      
      // جلب المصورين من مجموعة users بدلاً من photographers_data
      _allPhotographers = (await firestoreService.getAllPhotographerUsers().first);
      
      // طباعة عدد المصورين للتأكد من جلبهم
      debugPrint('تم جلب ${_allPhotographers.length} مصور');
      
      _lateDeductionAmountController.text = '50.0';
      _gracePeriodMinutesController.text = '10';
    } catch (e) {
      _errorMessage = 'خطأ في تحميل البيانات الأولية: $e';
      debugPrint('خطأ في تحميل البيانات: $e');
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
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: primaryColor, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: primaryColor, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
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
        _showErrorSnackBar('الرجاء اختيار تاريخ ووقت الفعالية.');
        return;
      }
      if (_selectedBookingId == null) {
        _showErrorSnackBar('الرجاء ربط الفعالية بحجز موجود.');
        return;
      }
      if (_selectedPhotographerIds.isEmpty) {
        _showErrorSnackBar('الرجاء تعيين مصور للفعالية.');
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

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
        assignedPhotographerIds: _selectedPhotographerIds,
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
        await firestoreService.updateBooking(
          _selectedBookingId!,
          {
            'status': 'scheduled',
            'photographerId': _selectedPhotographerIds.isNotEmpty ? _selectedPhotographerIds.first : null,
            'photographerIds': _selectedPhotographerIds,
          },
        );
        _showSuccessSnackBar('تم إضافة الفعالية وتعيين المصور بنجاح!');
        Navigator.of(context).pop();
      } else {
        _showErrorSnackBar('فشل إضافة الفعالية. الرجاء المحاولة مرة أخرى.');
      }
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message, style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.green, // Use green for success
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Colors.red, // Use red for error
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.currentUser == null || authService.userRole != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const LoadingIndicator();
    }

    return Scaffold(
      backgroundColor: lightGray,
      appBar: _buildAppBar(context),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('تفاصيل الفعالية'),
              const SizedBox(height: 16),
              _buildDropdownFormField(
                value: _selectedBookingId,
                labelText: 'ربط بحجز موجود (لم يُسند بعد)',
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
              _buildTextFormField(
                controller: _titleController,
                labelText: 'عنوان الفعالية',
                hintText: 'مثال: تصوير زفاف عائلة الأحمد',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال عنوان الفعالية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _descriptionController,
                labelText: 'وصف الفعالية (اختياري)',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildDateTimeSelection(),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _locationController,
                labelText: 'موقع الفعالية',
                hintText: 'مثال: قاعة النور، شارع الفرسان',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال موقع الفعالية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _lateDeductionAmountController,
                labelText: 'مبلغ الخصم عند التأخير (ريال يمني)',
                hintText: 'مثال: 50.00',
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
              _buildTextFormField(
                controller: _gracePeriodMinutesController,
                labelText: 'مدة السماح بالتأخير (دقائق)',
                hintText: 'مثال: 10',
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
              const SizedBox(height: 24),
              _buildSectionTitle('تعيين المصورين'),
              const SizedBox(height: 16),
              // عرض عدد المصورين المتاحين
              if (_allPhotographers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_outlined, color: Colors.orange.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'لا يوجد مصورون متاحون',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يجب إضافة مصورين أولاً من صفحة إدارة المصورين',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'المصورون المتاحون: ${_allPhotographers.length}',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _buildPhotographerAssignment(),
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
              const SizedBox(height: 20),
            ],
          ),
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
        'جدولة الفعاليات',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      // No search or grid toggle for this screen, as it's an "add" form
      actions: [
        // You can add other actions relevant to scheduling here if needed
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdownFormField<T>({
    required T? value,
    required String labelText,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    String? Function(T?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none, // Remove default border
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(color: Colors.grey[700]),
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _pickEventDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedEventDate == null
                          ? 'اختر تاريخ الفعالية'
                          : DateFormat('yyyy-MM-dd').format(_selectedEventDate!),
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedEventDate == null ? Colors.grey[700] : primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: _pickEventTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedEventTime == null
                          ? 'اختر وقت الفعالية'
                          : _selectedEventTime!.format(context),
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedEventTime == null ? Colors.grey[700] : primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotographerAssignment() {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المصورون المعينون',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _selectedPhotographerIds.map((id) {
              final photographer = _allPhotographers.firstWhere(
                (p) => p.uid == id,
                orElse: () => UserModel(
                  uid: id,
                  email: '',
                  fullName: 'مصور غير معروف',
                  role: UserRole.photographer,
                ),
              );
              return Chip(
                label: Text(photographer.fullName),
                backgroundColor: accentColor.withOpacity(0.1),
                labelStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedPhotographerIds.remove(id);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _allPhotographers.isEmpty ? null : _selectPhotographers,
              icon: Icon(
                _allPhotographers.isEmpty ? Icons.person_off_outlined : Icons.add_a_photo,
                color: Colors.white,
              ),
              label: Text(
                _allPhotographers.isEmpty 
                  ? 'لا يوجد مصورون متاحون'
                  : 'اختيار المصورين (${_selectedPhotographerIds.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _allPhotographers.isEmpty ? Colors.grey : primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}