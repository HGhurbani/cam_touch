// lib/features/admin/screens/admin_my_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../../core/utils/status_utils.dart';
import 'booking_detail_screen.dart';
import 'package:flutter/material.dart' as ui;

class AdminMyBookingsScreen extends StatefulWidget {
  const AdminMyBookingsScreen({super.key});

  @override
  State<AdminMyBookingsScreen> createState() => _AdminMyBookingsScreenState();
}

class _AdminMyBookingsScreenState extends State<AdminMyBookingsScreen>
    with TickerProviderStateMixin {
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _selectedDate;
  String? _statusFilter;
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _photographerController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showFilters = false;

  // الألوان الأساسية
  static const Color primaryColor = Color(0xFF024650);
  static const Color accentColor = Color(0xFFFF9403);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _photographerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryColor,
              secondary: accentColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryColor,
              secondary: accentColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  Future<void> _pickSelectedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryColor,
              secondary: accentColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedDate = null;
      _statusFilter = null;
      _clientController.clear();
      _photographerController.clear();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_admin_approval':
        return accentColor;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'deposit_paid':
        return Colors.blue;
      case 'scheduled':
        return accentColor;
      case 'completed':
        return primaryColor;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildModernFilterChip({
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: isSelected
                ? LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : primaryColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      width: 200,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        textDirection: ui.TextDirection.rtl,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButton<String?>(
        value: _statusFilter,
        hint: const Text('الحالة', style: TextStyle(fontSize: 14)),
        icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: null, child: Text('الكل')),
          DropdownMenuItem(value: 'pending_admin_approval', child: Text('قيد المراجعة')),
          DropdownMenuItem(value: 'approved', child: Text('موافق عليه')),
          DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
          DropdownMenuItem(value: 'deposit_paid', child: Text('دفع العربون')),
          DropdownMenuItem(value: 'scheduled', child: Text('مجدول')),
          DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
          DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
        ],
        onChanged: (val) => setState(() => _statusFilter = val),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookingDetailScreen(bookingId: booking.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(booking.status),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        getBookingStatusLabel(booking.status),
                        style: TextStyle(
                          color: _getStatusColor(booking.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.camera_alt, size: 18, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      booking.serviceType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('yyyy/MM/dd').format(booking.bookingDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'إدارة الحجوزات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: AnimatedRotation(
              turns: _showFilters ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.filter_list, color: Colors.white),
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<List<BookingModel>>(
          stream: firestoreService.getAllBookings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'جاري تحميل الحجوزات...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ: ${snapshot.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد حجوزات متاحة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            List<BookingModel> bookings = snapshot.data!;

            // تطبيق الفلاتر
            if (_statusFilter != null) {
              bookings = bookings.where((b) => b.status == _statusFilter).toList();
            }
            if (_fromDate != null) {
              bookings = bookings
                  .where((b) => !b.bookingDate.isBefore(_fromDate!))
                  .toList();
            }
            if (_toDate != null) {
              bookings = bookings
                  .where((b) => !b.bookingDate.isAfter(_toDate!))
                  .toList();
            }
            if (_selectedDate != null) {
              bookings = bookings
                  .where((b) =>
              b.bookingDate.year == _selectedDate!.year &&
                  b.bookingDate.month == _selectedDate!.month &&
                  b.bookingDate.day == _selectedDate!.day)
                  .toList();
            }
            final clientQuery = _clientController.text.trim();
            if (clientQuery.isNotEmpty) {
              bookings = bookings
                  .where((b) =>
              b.clientName.toLowerCase().contains(clientQuery.toLowerCase()) ||
                  b.clientId.contains(clientQuery))
                  .toList();
            }
            final photographerQuery = _photographerController.text.trim();
            if (photographerQuery.isNotEmpty) {
              bookings = bookings
                  .where((b) =>
              (b.photographerId ?? '').contains(photographerQuery) ||
                  (b.photographerIds ?? [])
                      .any((id) => id.contains(photographerQuery)))
                  .toList();
            }

            // ترتيب الحجوزات حسب التاريخ
            bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

            return Column(
              children: [
                // شريط الفلاتر
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showFilters ? null : 0,
                  child: _showFilters
                      ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // فلاتر التاريخ
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildModernFilterChip(
                                label: _fromDate == null
                                    ? 'من تاريخ'
                                    : DateFormat('yyyy/MM/dd').format(_fromDate!),
                                onTap: _pickFromDate,
                                isSelected: _fromDate != null,
                              ),
                              const SizedBox(width: 8),
                              _buildModernFilterChip(
                                label: _toDate == null
                                    ? 'إلى تاريخ'
                                    : DateFormat('yyyy/MM/dd').format(_toDate!),
                                onTap: _pickToDate,
                                isSelected: _toDate != null,
                              ),
                              const SizedBox(width: 8),
                              _buildModernFilterChip(
                                label: _selectedDate == null
                                    ? 'تاريخ معين'
                                    : DateFormat('yyyy/MM/dd').format(_selectedDate!),
                                onTap: _pickSelectedDate,
                                isSelected: _selectedDate != null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // فلاتر البحث
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildSearchField(
                                controller: _clientController,
                                hint: 'البحث بالعميل',
                                icon: Icons.person_search,
                              ),
                              const SizedBox(width: 12),
                              _buildSearchField(
                                controller: _photographerController,
                                hint: 'البحث بالمصور',
                                icon: Icons.camera_alt,
                              ),
                              const SizedBox(width: 12),
                              _buildStatusDropdown(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // زر مسح الفلاتر
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('مسح جميع الفلاتر'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                foregroundColor: Colors.grey.shade700,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      : const SizedBox(),
                ),

                // عدد النتائج
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'عدد الحجوزات: ${bookings.length}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),

                // قائمة الحجوزات
                Expanded(
                  child: bookings.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد نتائج مطابقة للفلترة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'جرب تعديل الفلاتر للحصول على نتائج',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        child: _buildBookingCard(bookings[index]),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}