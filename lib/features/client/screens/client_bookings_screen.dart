// lib/features/client/screens/client_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/status_utils.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_indicator.dart';

class ClientBookingsScreen extends StatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  State<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends State<ClientBookingsScreen> {
  UserModel? _clientUser;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (authService.currentUser != null) {
      _clientUser = await firestoreService.getUser(authService.currentUser!.uid);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    if (authService.currentUser == null || authService.userRole != UserRole.client) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const LoadingIndicator();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _buildBookingsList(firestoreService, authService),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return EnhancedAppBar(
      title: 'حجوزاتي',
      subtitle: Text(
        'إدارة جميع حجوزاتك',
        style: AppStyles.caption.copyWith(
          color: AppColors.whiteWithOpacity(0.8),
          fontSize: 12,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: AppStyles.marginLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تصفية الحجوزات',
            style: AppStyles.headline4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'الكل', AppColors.primary),
                const SizedBox(width: 12),
                _buildFilterChip('pending', 'في الانتظار', AppColors.secondary),
                const SizedBox(width: 12),
                _buildFilterChip('confirmed', 'مؤكد', AppColors.success),
                const SizedBox(width: 12),
                _buildFilterChip('completed', 'مكتمل', AppColors.info),
                const SizedBox(width: 12),
                _buildFilterChip('cancelled', 'ملغي', AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
          border: Border.all(
            color: isSelected ? color : AppColors.textLight.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected ? AppStyles.shadowMedium : null,
        ),
        child: Text(
          label,
          style: AppStyles.body2.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList(FirestoreService firestoreService, AuthService authService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<List<BookingModel>>(
        stream: firestoreService.getClientBookings(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer();
          }
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final allBookings = snapshot.data!;
          final filteredBookings = _filterBookings(allBookings);

          if (filteredBookings.isEmpty) {
            return _buildNoFilteredResults();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: filteredBookings.length,
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];
              return _buildBookingCard(booking, firestoreService);
            },
          );
        },
      ),
    );
  }

  List<BookingModel> _filterBookings(List<BookingModel> bookings) {
    if (_selectedFilter == 'all') return bookings;
    
    return bookings.where((booking) {
      final status = booking.status.toLowerCase();
      switch (_selectedFilter) {
        case 'pending':
          return status == 'pending' || status == 'في الانتظار';
        case 'confirmed':
          return status == 'confirmed' || status == 'مؤكد';
        case 'completed':
          return status == 'completed' || status == 'مكتمل';
        case 'cancelled':
          return status == 'cancelled' || status == 'ملغي';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildBookingCard(BookingModel booking, FirestoreService firestoreService) {
    final statusColor = _getStatusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
        boxShadow: AppStyles.shadowMedium,
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceType,
                    style: AppStyles.headline4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                  ),
                  child: Text(
                    getBookingStatusLabel(booking.status),
                    style: AppStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_month_rounded,
              'التاريخ',
              DateFormat('yyyy/MM/dd').format(booking.bookingDate),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time_rounded,
              'الوقت',
              booking.bookingTime,
            ),
            if (booking.photographerIds != null && booking.photographerIds!.isNotEmpty) ...[
              const SizedBox(height: 8),
              FutureBuilder<List<UserModel?>>(
                future: Future.wait(booking.photographerIds!.map((id) => firestoreService.getUser(id))),
                builder: (context, snapshot) {
                  final names = snapshot.data
                      ?.whereType<UserModel>()
                      .map((u) => u.fullName)
                      .join(', ') ??
                      'جاري التحميل...';
                  return _buildInfoRow(
                    Icons.person_rounded,
                    'المصور',
                    names,
                  );
                },
              ),
            ],
            if (booking.location != null && booking.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.location_on_rounded,
                'الموقع',
                booking.location!,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // يمكن إضافة تفاصيل أكثر للحجز هنا
                  },
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  label: const Text('تفاصيل أكثر'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
          ),
          child: Icon(icon, size: 16, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: AppStyles.caption.copyWith(
            color: AppColors.textLight,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppStyles.body1.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              size: 48,
              color: AppColors.secondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد حجوزات حتى الآن',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ رحلتك في التصوير بحجز أول جلسة',
            style: AppStyles.caption.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('احجز الآن'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilteredResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.textLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              size: 48,
              color: AppColors.textLight.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد حجوزات بهذا التصفية',
            style: AppStyles.headline4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب تصفية أخرى أو أزل التصفية لعرض جميع الحجوزات',
            style: AppStyles.caption.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
            boxShadow: AppStyles.shadowMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 150,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: 200,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ في تحميل البيانات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppStyles.caption.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'مؤكد':
        return AppColors.success;
      case 'pending':
      case 'في الانتظار':
        return AppColors.secondary;
      case 'cancelled':
      case 'ملغي':
        return AppColors.error;
      case 'completed':
      case 'مكتمل':
        return AppColors.info;
      default:
        return AppColors.textLight;
    }
  }
}
