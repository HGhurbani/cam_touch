// lib/features/auth/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole? initialRole; // أضف هذا المتغير

  const RegisterScreen({super.key, this.initialRole}); // قم بتعديل الـ constructor

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  late UserRole _selectedRole; // غيّرها إلى late وقم بتهيئتها في initState

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.client; // تهيئة الدور من initialRole أو كعميل افتراضي
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'كلمة المرور وتأكيد كلمة المرور غير متطابقين.';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      String? error = await authService.registerWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        role: _selectedRole,
      );

      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });

      if (error == null) {
        // إذا كان التسجيل ناجحًا، عد إلى شاشة تسجيل الدخول أو توجه مباشرة إلى لوحة التحكم
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التسجيل بنجاح! الرجاء تسجيل الدخول.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialRole == UserRole.photographer ? 'إضافة مصور جديد' : 'إنشاء حساب جديد')), // تعديل العنوان
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الاسم الكامل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
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
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء تأكيد كلمة المرور';
                    }
                    if (value != _passwordController.text) {
                      return 'كلمة المرور غير متطابقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                // إخفاء أو إظهار اختيار الدور بناءً على ما إذا كان المدير يقوم بالتسجيل
                if (widget.initialRole == null) // إذا لم يتم تمرير initialRole، يمكن للمستخدم اختيار دوره
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'أنا أُسجل كـ',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.client,
                        child: Text('عميل'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.photographer,
                        child: Text('مصور'),
                      ),
                    ],
                    onChanged: (UserRole? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRole = newValue;
                        });
                      }
                    },
                  ),
                if (widget.initialRole == null) // إذا أظهرنا الـ dropdown، نضيف SizedBox
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
                    ? const LoadingIndicator()
                    : CustomButton(
                  text: 'إنشاء حساب',
                  onPressed: _register,
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // العودة إلى شاشة تسجيل الدخول
                  },
                  child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}