// lib/features/photographer/screens/photographer_deductions_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // لفتح Google Maps

import '../../../core/models/attendance_model.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/user_model.dart'; // لجلب اسم المصور من الـ UID
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/loading_indicator.dart';
// Removed CustomAppBar as it's being replaced with a custom one in this file

class PhotographerDeductionsScreen extends StatefulWidget {
  const PhotographerDeductionsScreen({super.key});

  @override
  State<PhotographerDeductionsScreen> createState() => _PhotographerDeductionsScreenState();
}

class _PhotographerDeductionsScreenState extends State<PhotographerDeductionsScreen> {
  DateTime? _selectedDate;
  String _searchQuery = '';
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  // الألوان الأساسية
  static const Color primaryColor = Color(0xFF024650);
  static const Color accentColor = Color(0xFFFF9403);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _launchGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showErrorSnackBar('تعذر فتح الخريطة. يرجى التأكد من تثبيت تطبيق خرائط جوجل.');
    }
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

    final String currentPhotographerId = authService.currentUser!.uid;

    return Scaffold(
      backgroundColor: lightGray,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<AttendanceModel>>(
              // Reverted to the original method call
              stream: firestoreService.getPhotographerAttendanceForEvent(currentPhotographerId, ''),
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

                // تصفية السجلات لعرض الخصومات فقط (التي كانت متأخرة وتم تطبيق خصم عليها)
                List<AttendanceModel> deductionRecords = snapshot.data!.where(
                        (record) => record.isLate && record.lateDeductionApplied != null && record.lateDeductionApplied! > 0
                ).toList();

                deductionRecords = _filterRecords(deductionRecords, firestoreService); // Apply search and date filters

                if (deductionRecords.isEmpty) {
                  return _buildEmptyFilterState();
                }

                return _buildDeductionsContent(deductionRecords, firestoreService);
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      title: const Text(
        'تقارير الخصومات',
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
                hintText: 'البحث في الخصومات...',
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
          const SizedBox(height: 12),
          // فلتر التاريخ
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: primaryColor,
                        onPrimary: Colors.white,
                        onSurface: primaryColor,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: 'تصفية حسب التاريخ',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentColor, width: 2),
                ),
                suffixIcon: _selectedDate != null
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: primaryColor),
                  onPressed: () {
                    setState(() => _selectedDate = null);
                  },
                )
                    : const Icon(Icons.calendar_today, color: primaryColor),
              ),
              child: Text(
                _selectedDate == null
                    ? 'جميع التواريخ'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                style: TextStyle(color: _selectedDate == null ? textSecondary : textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsContent(List<AttendanceModel> records, FirestoreService firestoreService) {
    return Container(
      color: lightGray,
      child: _isGridView
          ? _buildGridView(records, firestoreService)
          : _buildListView(records, firestoreService),
    );
  }

  Widget _buildGridView(List<AttendanceModel> records, FirestoreService firestoreService) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: records.length,
        itemBuilder: (context, index) => _buildDeductionCard(records[index], firestoreService),
      ),
    );
  }

  Widget _buildListView(List<AttendanceModel> records, FirestoreService firestoreService) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) => _buildDeductionListItem(records[index], firestoreService),
    );
  }

  Widget _buildDeductionCard(AttendanceModel record, FirestoreService firestoreService) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _launchGoogleMaps(record.latitude, record.longitude),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    record.type == 'check_in' ? Icons.login : Icons.logout,
                    color: record.type == 'check_in' ? primaryColor : accentColor,
                    size: 24,
                  ),
                  _buildTypeChip(record.type),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder<EventModel?>(
                future: firestoreService.getEvent(record.eventId),
                builder: (context, eventSnapshot) {
                  if (eventSnapshot.hasData && eventSnapshot.data != null) {
                    return Text(
                      'الفعالية: ${eventSnapshot.data!.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.calendar_today, DateFormat('dd/MM/yyyy').format(record.timestamp.toLocal())),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.access_time, DateFormat('hh:mm a').format(record.timestamp.toLocal())),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'خصم: ${record.lateDeductionApplied!.toStringAsFixed(2)} ر.ي',
                  style: const TextStyle(color: errorColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 4),
              _buildLocationButton(record.latitude, record.longitude),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeductionListItem(AttendanceModel record, FirestoreService firestoreService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _launchGoogleMaps(record.latitude, record.longitude),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: record.type == 'check_in' ? primaryColor.withOpacity(0.1) : accentColor.withOpacity(0.1),
                radius: 24,
                child: Icon(
                  record.type == 'check_in' ? Icons.login : Icons.logout,
                  color: record.type == 'check_in' ? primaryColor : accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<EventModel?>(
                      future: firestoreService.getEvent(record.eventId),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.hasData && eventSnapshot.data != null) {
                          return Text(
                            'الفعالية: ${eventSnapshot.data!.title}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          );
                        }
                        return const Text('الفعالية: غير معروفة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'النوع: ${record.type == 'check_in' ? 'حضور' : 'انصراف'}',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'التاريخ والوقت: ${DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp.toLocal())}',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'خصم: ${record.lateDeductionApplied!.toStringAsFixed(2)} ر.ي',
                      style: const TextStyle(color: errorColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final color = type == 'check_in' ? primaryColor : accentColor;
    final label = type == 'check_in' ? 'حضور' : 'انصراف';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textPrimary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationButton(double lat, double lng) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _launchGoogleMaps(lat, lng),
        icon: const Icon(Icons.map_outlined, size: 18, color: primaryColor),
        label: const Text(
          'عرض الموقع',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          backgroundColor: primaryColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  List<AttendanceModel> _filterRecords(List<AttendanceModel> records, FirestoreService firestoreService) {
    List<AttendanceModel> filtered = records;

    if (_selectedDate != null) {
      filtered = filtered
          .where((r) =>
      r.timestamp.year == _selectedDate!.year &&
          r.timestamp.month == _selectedDate!.month &&
          r.timestamp.day == _selectedDate!.day)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      // To filter by event title, you'd ideally have event titles fetched alongside attendance records
      // or pre-cached. For this direct synchronous filter, it might be inefficient.
      // The original code was not filtering by event title in this part either.
      // I'm keeping the behavior consistent with the original intent.
      filtered = filtered.where((record) {
        // Here, we can only filter by what's directly in the record or easily accessible synchronously.
        return record.type.toLowerCase().contains(query) ||
            DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp.toLocal()).toLowerCase().contains(query);
      }).toList();
    }

    // Sort records by timestamp descending
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.money_off_csred_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد خصومات مسجلة حالياً.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر هنا الخصومات المطبقة على حضورك.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 18,
                color: errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
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
      ),
    );
  }
}