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
import '../../shared/widgets/custom_app_bar.dart';

class ClientRewardsScreen extends StatefulWidget {
  const ClientRewardsScreen({super.key});

  @override
  State<ClientRewardsScreen> createState() => _ClientRewardsScreenState();
}

class _ClientRewardsScreenState extends State<ClientRewardsScreen> {
  UserModel? _currentUserData;
  bool _isLoading = false;
  String? _errorMessage;

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
      setState(() => _errorMessage = 'الرجاء تسجيل الدخول أولاً.');
      _isLoading = false;
      return;
    }

    try {
      String? link = _currentUserData?.referralLink;
      if (link == null || link.isEmpty) {
        // إذا لم يكن هناك رابط موجود، قم بإنشائه
        link = await firestoreService.createReferralLink(authService.currentUser!.uid);
        if (link == null) {
          setState(() => _errorMessage = 'فشل توليد رابط الإحالة.');
          _isLoading = false;
          return;
        }
        // تحديث بيانات المستخدم في الواجهة بعد إنشاء الرابط
        _currentUserData = _currentUserData!.copyWith(referralLink: link);
      }

      // مشاركة الرابط باستخدام share_plus
      await share_plus.Share.share('مرحبًا! استخدم تطبيق Cam Touch لحجز جلسات التصوير الاحترافية. سجل الآن عبر رابط الإحالة الخاص بي لتحصل على مكافآت!\n$link');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مشاركة رابط الإحالة بنجاح!')),
      );
    } catch (e) {
      setState(() => _errorMessage = 'فشل مشاركة رابط الإحالة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
      appBar: const CustomAppBar(title: 'نقاطي ومكافآتي'),
      body: _isLoading
          ? const LoadingIndicator()
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentUserData != null) ...[
              Text(
                'نقاط مكافآتك الحالية: ${_currentUserData!.points}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              const Text(
                'برنامج الإحالة:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'شارك رابط الإحالة الخاص بك مع أصدقائك. ستحصل على نقاط مكافأة عندما يقوم أحدهم بالتسجيل وإكمال أول حجز له!',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              if (_currentUserData!.referralLink != null && _currentUserData!.referralLink!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('رابط الإحالة الخاص بك:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText(
                      _currentUserData!.referralLink!,
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              CustomButton(
                text: 'مشاركة رابط الإحالة',
                onPressed: () => _generateAndShareReferralLink(),
              ),
            ] else if (_errorMessage != null)
              Center(child: Text(_errorMessage!))
            else
              const Center(child: Text('لا توجد بيانات مستخدم لعرضها.')),
          ],
        ),
      ),
    );
  }
}
