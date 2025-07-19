// lib/core/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart'; // لاستخدام UserRole Enum

class UserModel {
  final String uid;
  final String phoneNumber;
  final String fullName;
  final UserRole role;
  final Timestamp? createdAt;
  /// Reward points accumulated by the user.
  ///
  /// Defaults to zero when not provided.
  final int points;

  /// Unique dynamic referral link for the user, if any.
  final String? referralLink;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    this.createdAt,
    this.points = 0, // قيمة افتراضية
    this.referralLink,
  });

  // Factory constructor لإنشاء UserModel من مستند Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data =
        doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return UserModel(
      uid: doc.id,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.unknown,
      ),
      createdAt: data['createdAt'] as Timestamp?,
      points: (data['points'] as num?)?.toInt() ?? 0,
      referralLink: data['referralLink'] as String?,
    );
  }

  // لتحويل UserModel إلى Map يمكن حفظه في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'role': role.toString().split('.').last,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      // persist the user's reward points
      'points': points,
      // store the referral link if it exists
      'referralLink': referralLink,
    };
  }

  // لتحديث حقول معينة
  UserModel copyWith({
    String? phoneNumber,
    String? fullName,
    UserRole? role,
    Timestamp? createdAt,
    /// New reward points value to override the current one.
    int? points,
    /// New referral link to override the current one.
    String? referralLink,
  }) {
    return UserModel(
      uid: uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      points: points ?? this.points,
      referralLink: referralLink ?? this.referralLink,
    );
  }
}
