// lib/features/admin/screens/admin_photographers_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/photographer_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/loading_indicator.dart';
// Removed CustomAppBar as it's being replaced with a custom one in this file

class AdminPhotographersManagementScreen extends StatefulWidget {
  const AdminPhotographersManagementScreen({super.key});

  @override
  State<AdminPhotographersManagementScreen> createState() => _AdminPhotographersManagementScreenState();
}

class _AdminPhotographersManagementScreenState extends State<AdminPhotographersManagementScreen> {
  String _searchQuery = '';
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  // الألوان الأساسية
  static const Color primaryColor = Color(0xFF024650);
  static const Color accentColor = Color(0xFFFF9403);
  static const Color lightGray = Color(0xFFF5F5F5); // Added for consistency

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      backgroundColor: lightGray, // Consistent background color
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: firestoreService.getAllPhotographerUsers(),
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

                final photographerUsers = _filterPhotographers(snapshot.data!);
                if (photographerUsers.isEmpty) {
                  return _buildEmptyFilterState();
                }

                return _buildPhotographersContent(photographerUsers, firestoreService);
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
        'إدارة المصورين',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () => setState(() => _isGridView = !_isGridView),
          tooltip: _isGridView ? 'عرض القائمة' : 'عرض الشبكة',
        ),
        IconButton(
          icon: const Icon(Icons.person_add),
          onPressed: () {
            Navigator.of(context).pushNamed(AppRouter.registerRoute, arguments: UserRole.photographer);
          },
          tooltip: 'إضافة مصور جديد',
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
                hintText: 'البحث عن مصورين...',
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

  Widget _buildPhotographersContent(List<UserModel> users, FirestoreService firestoreService) {
    return Container(
      color: lightGray,
      child: _isGridView
          ? _buildGridView(users, firestoreService)
          : _buildListView(users, firestoreService),
    );
  }

  Widget _buildGridView(List<UserModel> users, FirestoreService firestoreService) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9, // Adjusted aspect ratio for better card fit
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: users.length,
        itemBuilder: (context, index) => _buildPhotographerCard(users[index], firestoreService),
      ),
    );
  }

  Widget _buildListView(List<UserModel> users, FirestoreService firestoreService) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) => _buildPhotographerListItem(users[index], firestoreService),
    );
  }

  Widget _buildPhotographerCard(UserModel user, FirestoreService firestoreService) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToPhotographerDetail(user.uid),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FutureBuilder<PhotographerModel?>(
            future: firestoreService.getPhotographerData(user.uid),
            builder: (context, snapshot) {
              final photographer = snapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor,
                    radius: 24,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? user.phoneNumber ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (photographer != null) ...[
                    _buildInfoRow(Icons.star, 'التقييم: ${photographer.rating.toStringAsFixed(1)}'),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.account_balance_wallet, 'الرصيد: ${photographer.balance.toStringAsFixed(2)}'),
                  ],
                  // Add more photographer details as needed
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhotographerListItem(UserModel user, FirestoreService firestoreService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToPhotographerDetail(user.uid),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor,
                radius: 24,
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
                      user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? user.phoneNumber ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<PhotographerModel?>(
                      future: firestoreService.getPhotographerData(user.uid),
                      builder: (context, snapshot) {
                        final photographer = snapshot.data;
                        if (photographer != null) {
                          return Text(
                            'التقييم: ${photographer.rating.toStringAsFixed(1)} | الرصيد: ${photographer.balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                        return const SizedBox.shrink();
                      },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد مصورون لعرضهم حالياً',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف مصورين جدد لإدارة حساباتهم',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.registerRoute, arguments: UserRole.photographer),
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة مصور جديد'),
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
            'جرب تغيير معايير البحث',
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
      onPressed: () => Navigator.of(context).pushNamed(AppRouter.registerRoute, arguments: UserRole.photographer),
      backgroundColor: accentColor,
      icon: const Icon(Icons.person_add, color: Colors.white),
      label: const Text(
        'إضافة مصور',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<UserModel> _filterPhotographers(List<UserModel> users) {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      return user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (user.phoneNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  void _navigateToPhotographerDetail(String uid) {
    // You would typically navigate to a detail screen for the photographer here
    // For now, let's just show a snackbar or navigate to a placeholder.
    // Assuming AppRouter.photographerDetailRoute exists for this purpose.
    Navigator.of(context).pushNamed(
      AppRouter.photographerDetailRoute,
      arguments: uid,
    );
  }
}