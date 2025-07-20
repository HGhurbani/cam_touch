import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';

class ClientSplashScreen extends StatelessWidget {
  const ClientSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF024650), Color(0xFF03788A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/img/white_logo.png', height: 120),
            const SizedBox(height: 32),
            const Text(
              'مرحباً بك في Cam Touch',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'متخصصين في توثيق الفعاليات والمناسبات باحترافية عالية، وعدسة تلتقط أكثر من مجرد صورة — تخلّد لحظة، وتحكي قصة. بجودة لا تُضاهى وفريق مبدع، نمنح كل مناسبة طابعاً فنياً يبقى في الذاكرة',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'إنشاء حساب',
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRouter.registerRoute,
                  arguments: UserRole.client,
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.loginRoute);
              },
              child: const Text(
                'تسجيل الدخول',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
