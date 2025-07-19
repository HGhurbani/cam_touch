// lib/features/auth/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/custom_app_bar.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole? initialRole; // أضف هذا المتغير

  const RegisterScreen({super.key, this.initialRole}); // قم بتعديل الـ constructor

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  String? _verificationId;
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
    _phoneController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
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
          fullName: _fullNameController.text,
          role: _selectedRole,
        );
      }

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
      appBar: CustomAppBar(title: widget.initialRole == UserRole.photographer ? 'إضافة مصور جديد' : 'إنشاء حساب جديد'),
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
                    onPressed: () => _register(),
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