// lib/core/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart'; // لاستخدام UserRole Enum

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final Timestamp? createdAt;
  final int points; // حقل جديد: نقاط المكافآت
  final String? referralLink; // حقل جديد: رابط الإحالة الفريد

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.createdAt,
    this.points = 0, // قيمة افتراضية
    this.referralLink,
  });

  // Factory constructor لإنشاء UserModel من مستند Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: UserRole.values.firstWhere(
            (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.unknown,
      ),
      createdAt: data['createdAt'] as Timestamp?,
      points: data['points'] ?? 0, // قراءة النقاط
      referralLink: data['referralLink'], // قراءة رابط الإحالة
    );
  }

  // لتحويل UserModel إلى Map يمكن حفظه في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role.toString().split('.').last,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'points': points,
      'referralLink': referralLink,
    };
  }

  // لتحديث حقول معينة
  UserModel copyWith({
    String? email,
    String? fullName,
    UserRole? role,
    Timestamp? createdAt,
    int? points, // إضافة النقاط لـ copyWith
    String? referralLink, // إضافة رابط الإحالة لـ copyWith
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      points: points ?? this.points,
      referralLink: referralLink ?? this.referralLink,
    );
  }
}