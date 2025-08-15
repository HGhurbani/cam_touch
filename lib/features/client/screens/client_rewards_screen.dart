// lib/features/client/screens/client_rewards_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' as share_plus; // لتسهيل مشاركة الروابط

import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../../routes/app_router.dart';
// Removed CustomAppBar as it's being replaced with a custom one in this file

class ClientRewardsScreen extends StatefulWidget {
  const ClientRewardsScreen({super.key});

  @override
  State<ClientRewardsScreen> createState() => _ClientRewardsScreenState();
}

class _ClientRewardsScreenState extends State<ClientRewardsScreen> {
  UserModel? _currentUserData;
  bool _isLoading = false;
  String? _errorMessage;

  // الألوان الأساسية
  static const Color primaryColor = Color(0xFF024650);
  static const Color accentColor = Color(0xFFFF9403);
  static const Color lightGray = Color(0xFFF5F5F5); // Added for consistency
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (authService.currentUser != null) {
      try {
        _currentUserData = await firestoreService.getUser(authService.currentUser!.uid);
      } catch (e) {
        _errorMessage = 'خطأ في جلب بيانات المستخدم: $e';
      }
    } else {
      _errorMessage = 'لا يوجد مستخدم مسجل الدخول.';
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _generateAndShareReferralLink() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (authService.currentUser == null) {
      _showErrorSnackBar('الرجاء تسجيل الدخول أولاً.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      String? link = _currentUserData?.referralLink;
      if (link == null || link.isEmpty) {
        link = await firestoreService.createReferralLink(authService.currentUser!.uid);
        if (link == null) {
          _showErrorSnackBar('فشل توليد رابط الإحالة.');
          setState(() => _isLoading = false);
          return;
        }
        _currentUserData = _currentUserData!.copyWith(referralLink: link);
      }

      await share_plus.Share.share('مرحبًا! استخدم تطبيق كام تاتش لحجز جلسات التصوير الاحترافية. سجل الآن عبر رابط الإحالة الخاص بي لتحصل على مكافآت!\n$link');
      _showSuccessSnackBar('تم مشاركة رابط الإحالة بنجاح!');
    } catch (e) {
      _showErrorSnackBar('فشل مشاركة رابط الإحالة: $e');
    } finally {
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.currentUser == null ||
        authService.userRole != UserRole.client) {
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
          : _errorMessage != null
          ? _buildErrorState(_errorMessage!)
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero, // Remove default card margin
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _currentUserData != null
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('نقاط مكافآتك'),
                const SizedBox(height: 16),
                _buildPointsDisplay(),
                const SizedBox(height: 30),
                _buildSectionTitle('برنامج الإحالة'),
                const SizedBox(height: 10),
                Text(
                  'شارك رابط الإحالة الخاص بك مع أصدقائك. ستحصل على نقاط مكافأة عندما يقوم أحدهم بالتسجيل وإكمال أول حجز له!',
                  style: TextStyle(fontSize: 15, color: textPrimary),
                ),
                const SizedBox(height: 20),
                if (_currentUserData!.referralLink != null && _currentUserData!.referralLink!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رابط الإحالة الخاص بك:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                      const SizedBox(height: 8),
                      SelectableText(
                        _currentUserData!.referralLink!,
                        style: const TextStyle(fontSize: 14, color: accentColor, decoration: TextDecoration.underline),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                CustomButton(
                  text: 'مشاركة رابط الإحالة',
                  onPressed: () => _generateAndShareReferralLink(),
                ),
                const SizedBox(height: 12),
              ],
            )
                : _buildEmptyState(),
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
        'نقاطي ومكافآتي',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: const [
        // No specific actions for this screen
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

  Widget _buildPointsDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'نقاطك الحالية:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          Text(
            '${_currentUserData!.points}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accentColor),
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
            Icons.sentiment_dissatisfied_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات مستخدم لعرضها',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'تأكد من تسجيل الدخول بشكل صحيح.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUserData,
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
              onPressed: _loadUserData,
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