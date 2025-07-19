// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart'; // سنقوم بإنشاء هذا لاحقًا
import '../../shared/widgets/loading_indicator.dart'; // سنقوم بإنشاء هذا لاحقًا

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      String? error = await authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });

      if (error == null && authService.currentUser != null) {
        // إذا كان تسجيل الدخول ناجحًا، قم بالتوجيه بناءً على الدور
        // هذا الجزء سيعتمد على منطق تحديد الدور في AuthService
        // في الوقت الحالي، سنقوم فقط بالتحقق من وجود المستخدم
        // لاحقًا، سنستخدم authService.userRole لتحديد المسار الصحيح
        if (authService.userRole == UserRole.client) {
          Navigator.of(context).pushReplacementNamed(AppRouter.clientDashboardRoute);
        } else if (authService.userRole == UserRole.photographer) {
          Navigator.of(context).pushReplacementNamed(AppRouter.photographerDashboardRoute);
        } else if (authService.userRole == UserRole.admin) {
          Navigator.of(context).pushReplacementNamed(AppRouter.adminDashboardRoute);
        } else {
          // دور غير معروف أو لم يتم تحميله بعد، يمكن إعادة التوجيه إلى شاشة ترحيب أو تسجيل خروج
          Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال البريد الإلكتروني';
                    }
                    if (!value.contains('@')) {
                      return 'الرجاء إدخال بريد إلكتروني صالح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _isLoading
                    ? const LoadingIndicator() // مؤشر تحميل
                    : CustomButton( // زر مخصص
                  text: 'تسجيل الدخول',
                  onPressed: _signIn,
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRouter.registerRoute);
                  },
                  child: const Text('ليس لديك حساب؟ سجل الآن'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}