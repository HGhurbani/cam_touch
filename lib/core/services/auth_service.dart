// lib/core/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Enum لتعريف أدوار المستخدمين
enum UserRole {
  client,
  photographer,
  admin,
  unauthenticated, // لحالة عدم تسجيل الدخول
  unknown, // في حال لم نتمكن من تحديد الدور
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // متغير لتخزين المستخدم الحالي من Firebase Authentication
  User? _currentUser;
  User? get currentUser => _currentUser;

  // متغير لتخزين دور المستخدم
  UserRole _userRole = UserRole.unauthenticated;
  UserRole get userRole => _userRole;

  AuthService() {
    // الاستماع لتغييرات حالة المصادقة
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _updateUserRole(user); // تحديث دور المستخدم عند تغيير حالة المصادقة
      notifyListeners(); // إعلام المستمعين (مثل MyApp) بتغيير الحالة
    });
  }

  // إرسال رمز التحقق إلى رقم الهاتف
  Future<String?> sendCodeToPhone({
    required String phoneNumber,
    required void Function(String verificationId) codeSent,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) => throw e,
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          codeSent(verificationId);
        },
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unknown error occurred.';
    }
  }

  // تأكيد رمز الـ SMS وتسجيل/تسجيل دخول المستخدم
  Future<String?> verifySmsCode({
    required String verificationId,
    required String smsCode,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final userDoc = _firestore.collection('users').doc(userCredential.user!.uid);
      if (!(await userDoc.get()).exists) {
        await userDoc.set({
          'uid': userCredential.user!.uid,
          'phoneNumber': userCredential.user!.phoneNumber,
          'fullName': fullName,
          'role': role.toString().split('.').last,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unknown error occurred.';
    }
  }

  // تسجيل دخول سريع برقم هاتف تجريبي (أثناء التطوير)
  Future<String?> quickLogin({
    required String phoneNumber,
    required String smsCode,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      String? verificationId;
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCredential = await _auth.signInWithCredential(credential);
          await _createUserIfNeeded(userCredential.user!, fullName, role);
        },
        verificationFailed: (FirebaseAuthException e) => throw e,
        codeSent: (String id, int? resendToken) async {
          verificationId = id;
          PhoneAuthCredential credential =
              PhoneAuthProvider.credential(verificationId: id, smsCode: smsCode);
          final userCredential = await _auth.signInWithCredential(credential);
          await _createUserIfNeeded(userCredential.user!, fullName, role);
        },
        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;
        },
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unknown error occurred.';
    }
  }

  Future<void> _createUserIfNeeded(
      User user, String fullName, UserRole role) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    if (!(await userDoc.get()).exists) {
      await userDoc.set({
        'uid': user.uid,
        'phoneNumber': user.phoneNumber,
        'fullName': fullName,
        'role': role.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // دالة داخلية لتحديث دور المستخدم بناءً على بياناته في Firestore
  Future<void> _updateUserRole(User? user) async {
    if (user == null) {
      _userRole = UserRole.unauthenticated;
    } else {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          String roleString = userDoc.get('role');
          _userRole = UserRole.values.firstWhere(
                (e) => e.toString().split('.').last == roleString,
            orElse: () => UserRole.unknown,
          );
        } else {
          _userRole = UserRole.unknown; // المستخدم موجود في Auth ولكن لا يوجد له مستند في Firestore
        }
      } catch (e) {
        debugPrint('Error fetching user role: $e');
        _userRole = UserRole.unknown;
      }
    }
    notifyListeners();
  }
}