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
import 'photographer_schedule_screen.dart';
import '../../../core/utils/status_utils.dart';

class PhotographerDashboardScreen extends StatefulWidget {
  const PhotographerDashboardScreen({super.key});

  @override
  State<PhotographerDashboardScreen> createState() => _PhotographerDashboardScreenState();
}

class _PhotographerDashboardScreenState extends State<PhotographerDashboardScreen>
    with TickerProviderStateMixin {
  PhotographerModel? _photographerData;
  String? _errorMessage;
  UserModel? _photographerUser;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  // Removed _currentPageIndex as it's no longer needed after removing bottomNavigationBar

  // Theme colors
  static const Color primaryColor = Color(0xFF024650);
  static const Color accentColor = Color(0xFFFF9403);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadPhotographerData(),
      _loadUserData(),
    ]);
    _animationController.forward();
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

    _showLoadingDialog();

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);

    Position? position = await locationService.getCurrentLocation();
    Navigator.of(context).pop(); // Close loading dialog

    if (position == null) {
      _showErrorSnackBar('لا يمكن الحصول على الموقع. يرجى التأكد من تفعيل خدمات الموقع وإعطاء الإذن.');
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
        _showSuccessSnackBar('تم تسجيل ${type == 'check_in' ? 'الحضور' : 'الانصراف'} بنجاح!');
        _loadPhotographerData();
      } else {
        _showErrorSnackBar('فشل تسجيل ${type == 'check_in' ? 'الحضور' : 'الانصراف'}.');
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ: $e');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'جارٍ تسجيل البيانات...',
                style: TextStyle(
                  fontSize: 16,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        backgroundColor: successColor,
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
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
    } else if (_tabController.index == 1) {
      start = now.subtract(Duration(days: now.weekday - 1));
      end = start.add(const Duration(days: 7));
    } else {
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

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رصيدك المالي',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_photographerData?.balance.toStringAsFixed(2) ?? '0.00'} ريال يمني',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'إجمالي الخصومات: ${_photographerData?.totalDeductions.toStringAsFixed(2) ?? '0.00'} ريال',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  child: Icon(Icons.event, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(event.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    getEventStatusLabel(event.status),
                    style: TextStyle(
                      color: _getStatusColor(event.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.access_time, 'التاريخ والوقت',
                DateFormat('yyyy-MM-dd HH:mm').format(event.eventDateTime.toLocal())),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'الموقع', event.location),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.money_off, 'خصم التأخير',
                '${(event.lateDeductionAmount ?? 0.0).toStringAsFixed(2)} ريال يمني'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.timer, 'مدة السماح بالتأخير', '${event.gracePeriodMinutes ?? 10} دقيقة'),
            const SizedBox(height: 20),
            FutureBuilder<bool>(
              future: _hasCheckedIn(event.id),
              builder: (context, checkInSnapshot) {
                if (checkInSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ));
                }
                final hasCheckedIn = checkInSnapshot.data ?? false;
                return FutureBuilder<bool>(
                  future: _hasCheckedOut(event.id),
                  builder: (context, checkOutSnapshot) {
                    if (checkOutSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ));
                    }
                    final hasCheckedOut = checkOutSnapshot.data ?? false;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildAttendanceButton(
                            'تسجيل حضور',
                            Icons.login,
                            hasCheckedIn ? null : () => _recordAttendance(event, 'check_in'),
                            hasCheckedIn ? Colors.grey : successColor,
                            hasCheckedIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAttendanceButton(
                            'تسجيل انصراف',
                            Icons.logout,
                            (hasCheckedIn && !hasCheckedOut) ? () => _recordAttendance(event, 'check_out') : null,
                            (hasCheckedIn && !hasCheckedOut) ? errorColor : Colors.grey,
                            hasCheckedOut,
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
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceButton(String text, IconData icon, VoidCallback? onPressed, Color color, bool isCompleted) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        isCompleted ? Icons.check_circle : icon,
        size: 18,
        color: Colors.white,
      ),
      label: Text(
        isCompleted ? 'تم' : text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, double paid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.camera_alt, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy-MM-dd').format(booking.bookingDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'التكلفة: ${(booking.estimatedCost ?? 0.0).toStringAsFixed(2)} ريال',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${paid.toStringAsFixed(2)} ريال',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: paid > 0 ? successColor : textSecondary,
                ),
              ),
              Text(
                'المدفوع',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return successColor;
      case 'pending':
        return accentColor;
      case 'cancelled':
        return errorColor;
      default:
        return textSecondary;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
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

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: accentColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'لوحة تحكم المصور',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PhotographerScheduleScreen()),
                );
              },
              tooltip: 'جدولي الزمني',
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.photographerDeductionsRoute);
              },
              tooltip: 'تقارير الخصومات',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'logout') {
                  authService.signOut();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: errorColor),
                      const SizedBox(width: 8),
                      const Text('تسجيل الخروج'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: primaryColor,
                      child: Text(
                        (_photographerUser?.fullName?.isNotEmpty == true)
                            ? _photographerUser!.fullName!.substring(0, 1).toUpperCase()
                            : 'م',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً بك',
                            style: TextStyle(
                              fontSize: 16,
                              color: textSecondary,
                            ),
                          ),
                          Text(
                            _photographerUser?.fullName ?? authService.currentUser?.email ?? 'مصور',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Balance Card
                if (_photographerData != null) _buildBalanceCard(),
                const SizedBox(height: 24),

                // Quick Actions
                Row(
                  children: [
                    _buildQuickActionCard(
                      Icons.calendar_month,
                      'حجوزاتي',
                      'عرض الحجوزات والمدفوعات',
                          () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const PhotographerScheduleScreen()),
                        );
                      },
                    ),
                    // const SizedBox(width: 12),
                    // _buildQuickActionCard(
                    //   Icons.receipt_long,
                    //   'التقارير',
                    //   'تقارير الخصومات',
                    //       () {
                    //     Navigator.of(context).pushNamed(AppRouter.photographerDeductionsRoute);
                    //   },
                    // ),
                  ],
                ),
                const SizedBox(height: 32),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: errorColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: errorColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: errorColor, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Events Section
                Text(
                  'فعالياتي القادمة والحالية',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: primaryColor,
                    labelColor: primaryColor,
                    unselectedLabelColor: textSecondary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'اليوم'),
                      Tab(text: 'الأسبوع'),
                      Tab(text: 'الشهر'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Events List
                SizedBox(
                  height: 400,
                  child: StreamBuilder<List<EventModel>>(
                    stream: firestoreService.getPhotographerEvents(authService.currentUser!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: errorColor),
                              const SizedBox(height: 16),
                              Text('خطأ: ${snapshot.error}', style: TextStyle(color: errorColor)),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 48, color: textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد فعاليات مجدولة لك حالياً',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final events = _filterEvents(snapshot.data!);
                      if (events.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, size: 48, color: textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد فعاليات للفترة المحددة',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _buildEventCard(event);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Bookings Section
                Text(
                  'حجوزاتك والمدفوعات',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                StreamBuilder<List<BookingModel>>(
                  stream: firestoreService.getPhotographerBookings(authService.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 200,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Container(
                        height: 100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 32, color: errorColor),
                              const SizedBox(height: 8),
                              Text(
                                'خطأ: ${snapshot.error}',
                                style: TextStyle(color: errorColor),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        height: 150,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_camera, size: 48, color: textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد حجوزات حالياً',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final bookings = snapshot.data!.take(5).toList(); // Show only recent 5
                    return Column(
                      children: [
                        ...bookings.map((booking) {
                          final paid = booking.photographerPayments?[authService.currentUser!.uid] ?? 0.0;
                          return _buildBookingCard(booking, paid);
                        }).toList(),
                        if (snapshot.data!.length > 5)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 16),
                            child: TextButton.icon(
                              onPressed: () {
                                // Navigate to full bookings screen
                              },
                              icon: Icon(Icons.visibility, color: primaryColor),
                              label: Text(
                                'عرض جميع الحجوزات',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // Removed bottomNavigationBar
      ),
    );
  }
}