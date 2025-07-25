// lib/core/models/attendance_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id; // Attendance Record ID
  final String photographerId;
  final String eventId;
  final String type; // 'check_in' or 'check_out'
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? locationAddress; // nullable for future geocoding
  final bool isLate; // defaults to false
  final double? lateDeductionApplied;

  AttendanceModel({
    required this.id,
    required this.photographerId,
    required this.eventId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.locationAddress,
    this.isLate = false,
    this.lateDeductionApplied,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return AttendanceModel(
      id: doc.id,
      photographerId: data?['photographerId'] ?? '',
      eventId: data?['eventId'] ?? '',
      type: data?['type'] ?? '',
      timestamp: (data?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (data?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data?['longitude'] as num?)?.toDouble() ?? 0.0,
      locationAddress: data?['locationAddress'],
      isLate: data?['isLate'] ?? false,
      lateDeductionApplied: (data?['lateDeductionApplied'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'photographerId': photographerId,
      'eventId': eventId,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'isLate': isLate,
      'lateDeductionApplied': lateDeductionApplied,
    };
  }
}

