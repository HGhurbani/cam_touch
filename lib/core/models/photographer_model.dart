// lib/core/models/photographer_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PhotographerModel {
  final String uid; // Firestore Document ID (same as User UID)
  final String bio;
  final List<String> specialties; // أنواع التصوير التي يتقنها
  final double rating;
  final int totalBookings;
  final double balance; // رصيد المستحقات أو المديونية
  final double totalDeductions; // إجمالي الخصومات

  PhotographerModel({
    required this.uid,
    this.bio = '',
    this.specialties = const [],
    this.rating = 0.0,
    this.totalBookings = 0,
    this.balance = 0.0,
    this.totalDeductions = 0.0,
  });

  factory PhotographerModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PhotographerModel(
      uid: doc.id,
      bio: data['bio'] ?? '',
      specialties: List<String>.from(data['specialties'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalBookings: data['totalBookings'] ?? 0,
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      totalDeductions: (data['totalDeductions'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bio': bio,
      'specialties': specialties,
      'rating': rating,
      'totalBookings': totalBookings,
      'balance': balance,
      'totalDeductions': totalDeductions,
    };
  }

  PhotographerModel copyWith({
    String? bio,
    List<String>? specialties,
    double? rating,
    int? totalBookings,
    double? balance,
    double? totalDeductions,
  }) {
    return PhotographerModel(
      uid: uid,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      rating: rating ?? this.rating,
      totalBookings: totalBookings ?? this.totalBookings,
      balance: balance ?? this.balance,
      totalDeductions: totalDeductions ?? this.totalDeductions,
    );
  }
}
