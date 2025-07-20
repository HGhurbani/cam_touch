import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../../core/utils/status_utils.dart';

class AdminPhotographerAccountsScreen extends StatefulWidget {
  const AdminPhotographerAccountsScreen({super.key});

  @override
  State<AdminPhotographerAccountsScreen> createState() => _AdminPhotographerAccountsScreenState();
}

class _AdminPhotographerAccountsScreenState extends State<AdminPhotographerAccountsScreen>
    with TickerProviderStateMixin {
  DateTime? _selectedDate;
  String? _selectedPhotographerId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isFiltering = false;

  // Theme Colors
  static const Color primaryColor = Color(0xFF024650);
  static const Color accentColor = Color(0xFFFF9403);
  static const Color cardColor = Color(0xFFF8F9FA);
  static const Color successColor = Color(0xFF10B981);
  static const Color textSecondary = Color(0xFF6B7280);

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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    setState(() => _isFiltering = true);

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
    setState(() => _isFiltering = false);
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedPhotographerId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم مسح المرشحات'),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFilterSection(List<UserModel> photographers) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'تصفية النتائج',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildPhotographerDropdown(photographers),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildDateSelector(),
              ),
              const SizedBox(width: 8),
              if (_selectedDate != null || _selectedPhotographerId != null)
                _buildClearButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotographerDropdown(List<UserModel> photographers) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _selectedPhotographerId,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'جميع المصورين',
              style: TextStyle(color: textSecondary),
            ),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.keyboard_arrow_down, color: primaryColor),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('جميع المصورين'),
              ),
            ),
            ...photographers.map(
                  (p) => DropdownMenuItem(
                value: p.uid,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: accentColor.withOpacity(0.2),
                        child: Text(
                          p.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p.fullName)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          onChanged: (val) => setState(() => _selectedPhotographerId = val),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _isFiltering ? null : _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'اختر التاريخ'
                    : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                style: TextStyle(
                  color: _selectedDate == null ? textSecondary : primaryColor,
                  fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            if (_isFiltering)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.clear_rounded, color: Colors.red),
        onPressed: _clearFilters,
        tooltip: 'مسح المرشحات',
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, List<UserModel> photographers) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          booking.serviceType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: successColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          getBookingStatusLabel(booking.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.white.withOpacity(0.8), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMMM yyyy', 'ar').format(booking.bookingDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.person_rounded, 'العميل', '${booking.clientName} (${booking.clientEmail})'),
                  _buildInfoRow(Icons.location_on_rounded, 'الموقع', booking.location),
                  _buildInfoRow(Icons.access_time_rounded, 'الوقت', booking.bookingTime),

                  const SizedBox(height: 16),

                  // Financial info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildAmountInfo(
                            'التكلفة الإجمالية',
                            booking.estimatedCost,
                            accentColor,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        Expanded(
                          child: _buildAmountInfo(
                            'المبلغ المدفوع',
                            booking.paidAmount,
                            successColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Photographers section
                  _buildPhotographersSection(booking, photographers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(2)} ر.ي',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotographersSection(BookingModel booking, List<UserModel> photographers) {
    final photographerIds = booking.photographerIds ??
        (booking.photographerId != null ? [booking.photographerId!] : <String>[]);

    if (photographerIds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المصورون المشاركون',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...photographerIds.map((pid) => _buildPhotographerTile(booking, pid)),
      ],
    );
  }

  Widget _buildPhotographerTile(BookingModel booking, String photographerId) {
    return FutureBuilder<UserModel?>(
      future: Provider.of<FirestoreService>(context, listen: false).getUser(photographerId),
      builder: (context, userSnapshot) {
        final photographer = userSnapshot.data;
        final photographerName = photographer?.fullName ?? photographerId;
        final paidAmount = booking.photographerPayments?[photographerId] ?? 0.0;
        final isPaid = paidAmount > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isPaid ? successColor.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
            color: isPaid ? successColor.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isPaid ? successColor.withOpacity(0.2) : accentColor.withOpacity(0.2),
                child: Text(
                  photographerName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? successColor : accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photographerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'المدفوع: ${paidAmount.toStringAsFixed(2)} ر.ي',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPaid ? successColor : textSecondary,
                        fontWeight: isPaid ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPaymentButton(booking, photographerId, isPaid),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentButton(BookingModel booking, String photographerId, bool isPaid) {
    return ElevatedButton.icon(
      onPressed: () => _showPaymentDialog(booking, photographerId),
      icon: Icon(
        isPaid ? Icons.edit_rounded : Icons.payment_rounded,
        size: 16,
      ),
      label: Text(isPaid ? 'تعديل' : 'دفع'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPaid ? accentColor : primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  Future<void> _showPaymentDialog(BookingModel booking, String photographerId) async {
    final controller = TextEditingController();
    final currentAmount = booking.photographerPayments?[photographerId] ?? 0.0;
    controller.text = currentAmount > 0 ? currentAmount.toString() : '';

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تسجيل الدفع للمصور',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'المبلغ (ريال يمني)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor),
                ),
                prefixIcon: const Icon(Icons.attach_money_rounded, color: accentColor),
              ),
            ),
            if (currentAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'المبلغ الحالي: ${currentAmount.toStringAsFixed(2)} ر.ي',
                  style: const TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.pop(context, val);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (amount != null && context.mounted) {
      try {
        await Provider.of<FirestoreService>(context, listen: false)
            .recordPhotographerPayment(booking.id, photographerId, amount);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم تسجيل الدفع بنجاح'),
              backgroundColor: successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تسجيل الدفع: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'إدارة حسابات المصورين'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<List<UserModel>>(
          stream: firestoreService.getAllPhotographerUsers(),
          builder: (context, photographersSnapshot) {
            if (photographersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingIndicator());
            }
            if (photographersSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.6)),
                    const SizedBox(height: 16),
                    Text('خطأ: ${photographersSnapshot.error}'),
                  ],
                ),
              );
            }

            final photographers = photographersSnapshot.data ?? [];

            return Column(
              children: [
                _buildFilterSection(photographers),
                Expanded(
                  child: StreamBuilder<List<BookingModel>>(
                    stream: _selectedDate == null
                        ? firestoreService.getAllBookings()
                        : firestoreService.getBookingsByDate(_selectedDate!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: LoadingIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.6)),
                              const SizedBox(height: 16),
                              Text('خطأ: ${snapshot.error}'),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded, size: 64, color: textSecondary),
                              const SizedBox(height: 16),
                              const Text('لا توجد حجوزات', style: TextStyle(color: textSecondary)),
                            ],
                          ),
                        );
                      }

                      final bookings = snapshot.data!
                          .where((b) => b.status == 'completed')
                          .where((b) =>
                      (b.photographerIds != null && b.photographerIds!.isNotEmpty) ||
                          b.photographerId != null)
                          .where((b) {
                        if (_selectedPhotographerId == null) return true;
                        final ids = b.photographerIds ??
                            (b.photographerId != null ? [b.photographerId!] : <String>[]);
                        return ids.contains(_selectedPhotographerId);
                      }).toList();

                      if (bookings.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 64, color: textSecondary),
                              const SizedBox(height: 16),
                              const Text('لا توجد نتائج للمرشحات المحددة', style: TextStyle(color: textSecondary)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          return _buildBookingCard(bookings[index], photographers);
                        },
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