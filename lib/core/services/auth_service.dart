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

  // تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // لا يوجد خطأ
    } on FirebaseAuthException catch (e) {
      return e.message; // إرجاع رسالة الخطأ
    } catch (e) {
      return 'An unknown error occurred.';
    }
  }

  // تسجيل مستخدم جديد بالبريد الإلكتروني وكلمة المرور وتحديد دوره
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // حفظ بيانات المستخدم الإضافية في Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'fullName': fullName,
        'role': role.toString().split('.').last, // تحويل enum إلى string (مثال: 'client')
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null; // لا يوجد خطأ
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unknown error occurred.';
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