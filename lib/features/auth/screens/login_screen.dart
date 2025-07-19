// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_app_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  String? _verificationId;
  bool _isLoading = false;
  String? _errorMessage;

  // بيانات تسجيل الدخول السريع للحسابات التجريبية
  static const _clientPhone = '+967700000001';
  static const _photographerPhone = '+967700000002';
  static const _adminPhone = '+967700000003';

  Future<void> _signInWithPhone() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    String? error;
    if (_verificationId == null) {
      error = await authService.sendCodeToPhone(
        phoneNumber: _phoneController.text,
        codeSent: (id) => setState(() => _verificationId = id),
      );
    } else {
      error = await authService.verifySmsCode(
        verificationId: _verificationId!,
        smsCode: _smsController.text,
        fullName: '',
        role: UserRole.client,
      );
    }

    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });

    if (error == null && _verificationId != null && _smsController.text.isNotEmpty) {
      if (authService.userRole == UserRole.client) {
        Navigator.of(context).pushReplacementNamed(AppRouter.clientDashboardRoute);
      } else if (authService.userRole == UserRole.photographer) {
        Navigator.of(context).pushReplacementNamed(AppRouter.photographerDashboardRoute);
      } else if (authService.userRole == UserRole.admin) {
        Navigator.of(context).pushReplacementNamed(AppRouter.adminDashboardRoute);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      }
    }
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      await _signInWithPhone();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'تسجيل الدخول'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "رقم الهاتف",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "الرجاء إدخال رقم الهاتف";
                    }
                    if (!RegExp(r'^\+?967[0-9]{8}\$').hasMatch(value)) {
                      return "الرجاء إدخال رقم يمني صحيح";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                if (_verificationId != null)
                  TextFormField(
                    controller: _smsController,
                    decoration: const InputDecoration(
                      labelText: "رمز التحقق",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_verificationId != null && (value == null || value.isEmpty)) {
                        return "أدخل رمز التحقق";
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
                    onPressed: () => _signIn(),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRouter.registerRoute);
                  },
                  child: const Text('ليس لديك حساب؟ سجل الآن'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 32.0),
                  const Text(
                    'تسجيل سريع (أثناء التطوير)',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8.0),
                  CustomButton(
                    text: 'دخول كعميل',
                    onPressed: () {
                      _phoneController.text = _clientPhone;
                      _signInWithPhone();
                    },
                  ),
                  const SizedBox(height: 8.0),
                  CustomButton(
                    text: 'دخول كمصور',
                    onPressed: () {
                      _phoneController.text = _photographerPhone;
                      _signInWithPhone();
                    },
                  ),
                  const SizedBox(height: 8.0),
                  CustomButton(
                    text: 'دخول كمدير',
                    onPressed: () {
                      _phoneController.text = _adminPhone;
                      _signInWithPhone();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}