// lib/features/admin/screens/admin_bookings_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_app_bar.dart';
import 'booking_detail_screen.dart';
import '../../../core/utils/status_utils.dart';

class AdminBookingsManagementScreen extends StatefulWidget {
  const AdminBookingsManagementScreen({super.key});

  @override
  State<AdminBookingsManagementScreen> createState() => _AdminBookingsManagementScreenState();
}

class _AdminBookingsManagementScreenState extends State<AdminBookingsManagementScreen>
    with TickerProviderStateMixin {
  String? _statusFilter;
  String _searchQuery = '';
  bool _isGridView = false;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // الألوان الأساسية
  static const Color primaryColor = Color(0xFF024650);
  static const Color accentColor = Color(0xFFFF9403);

  final List<Map<String, dynamic>> _statusTabs = [
    {'status': null, 'label': 'الكل', 'icon': Icons.all_inclusive},
    {'status': 'pending_admin_approval', 'label': 'قيد المراجعة', 'icon': Icons.pending_actions},
    {'status': 'approved', 'label': 'موافق عليه', 'icon': Icons.check_circle},
    {'status': 'rejected', 'label': 'مرفوض', 'icon': Icons.cancel},
    {'status': 'deposit_paid', 'label': 'مدفوع العربون', 'icon': Icons.payment},
    {'status': 'scheduled', 'label': 'مجدول', 'icon': Icons.event_available},
    {'status': 'completed', 'label': 'مكتمل', 'icon': Icons.done_all},
    {'status': 'cancelled', 'label': 'ملغي', 'icon': Icons.cancel_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    // تحقق من أن المستخدم هو مدير
    if (authService.currentUser == null || authService.userRole != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const LoadingIndicator();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: firestoreService.getAllBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final bookings = _filterBookings(snapshot.data!);
                return TabBarView(
                  controller: _tabController,
                  children: _statusTabs.map((tab) {
                    final filteredBookings = tab['status'] == null
                        ? bookings
                        : bookings.where((b) => b.status == tab['status']).toList();

                    return _buildBookingsContent(filteredBookings);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      title: const Text(
        'إدارة الحجوزات',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () => setState(() => _isGridView = !_isGridView),
          tooltip: _isGridView ? 'عرض القائمة' : 'عرض الشبكة',
        ),

      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // شريط البحث
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'البحث في الحجوزات...',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      // Removed any padding from the Container to ensure TabBar starts from the edge
      child: TabBar(
        controller: _tabController,
        isScrollable: true, // Keep scrollable for "تجوال فيه"
        tabAlignment: TabAlignment.start, // Align tabs to the start (right in RTL)
        indicatorColor: accentColor,
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
        tabs: _statusTabs.map((tab) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab['icon'], size: 18),
                const SizedBox(width: 4),
                Text(tab['label']),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingsContent(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return _buildEmptyFilterState();
    }

    return Container(
      color: Colors.grey[50],
      child: _isGridView ? _buildGridView(bookings) : _buildListView(bookings),
    );
  }

  Widget _buildGridView(List<BookingModel> bookings) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: bookings.length,
        itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
      ),
    );
  }

  Widget _buildListView(List<BookingModel> bookings) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _buildBookingListItem(bookings[index]),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToBookingDetail(booking.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor,
                    radius: 16,
                    child: Text(
                      booking.clientName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.work_outline, booking.serviceType),
              const SizedBox(height: 6),
              _buildInfoRow(
                Icons.calendar_today,
                DateFormat('dd/MM/yyyy').format(booking.bookingDate),
              ),
              const Spacer(),
              _buildStatusChip(booking.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingListItem(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToBookingDetail(booking.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor,
                radius: 24,
                child: Text(
                  booking.clientName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.serviceType,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(booking.bookingDate),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _buildStatusChip(booking.status),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final statusColor = _getBookingStatusColor(status);
    final statusIcon = _getBookingStatusIcon(status);
    final statusLabel = getBookingStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد حجوزات حالياً',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر الحجوزات الجديدة هنا',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.adminAddBookingRoute),
            icon: const Icon(Icons.add),
            label: const Text('إضافة حجز جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب تغيير معايير البحث أو الفلتر',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.of(context).pushNamed(AppRouter.adminAddBookingRoute),
      backgroundColor: accentColor,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'حجز جديد',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<BookingModel> _filterBookings(List<BookingModel> bookings) {
    if (_searchQuery.isEmpty) return bookings;

    return bookings.where((booking) {
      return booking.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          booking.serviceType.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _navigateToBookingDetail(String bookingId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(bookingId: bookingId),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فلتر متقدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('المزيد من خيارات الفلتر قريباً...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('موافق'),
            ),
          ],
        ),
      ),
    );
  }

  // دوال مساعدة لتحديد الأيقونة واللون بناءً على حالة الحجز
  IconData _getBookingStatusIcon(String status) {
    switch (status) {
      case 'pending_admin_approval':
        return Icons.pending_actions;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'deposit_paid':
        return Icons.payment;
      case 'scheduled':
        return Icons.event_available;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info;
    }
  }

  Color _getBookingStatusColor(String status) {
    switch (status) {
      case 'pending_admin_approval':
        return accentColor; // استخدام اللون المحدد
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'deposit_paid':
        return primaryColor; // استخدام اللون الأساسي
      case 'scheduled':
        return Colors.teal;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}