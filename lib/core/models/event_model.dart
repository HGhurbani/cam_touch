// lib/core/models/event_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id; // Event ID (Firestore Document ID)
  final String bookingId; // ربط بالـ Booking
  final List<String> assignedPhotographerIds; // يمكن إسناد أكثر من مصور
  final String title; // مثلاً "تصوير حفل زفاف - [اسم العميل]"
  final String description;
  final DateTime eventDateTime; // وقت وتاريخ الفعالية
  final String location;
  final double requiredArrivalTimeOffsetMinutes; // مثلاً 30 دقيقة قبل البدء
  final double lateDeductionAmount; // مبلغ الخصم في حال التأخير
  final int gracePeriodMinutes; // مدة السماح بالتأخير بالدقائق (مثلاً 10)
  final String status; // 'scheduled', 'ongoing', 'completed', 'cancelled'
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  EventModel({
    required this.id,
    required this.bookingId,
    required this.assignedPhotographerIds,
    required this.title,
    this.description = '',
    required this.eventDateTime,
    required this.location,
    this.requiredArrivalTimeOffsetMinutes = 30, // 30 minutes before event start
    this.lateDeductionAmount = 0.0,
    this.gracePeriodMinutes = 10,
    this.status = 'scheduled',
    required this.createdAt,
    this.updatedAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      assignedPhotographerIds: List<String>.from(data['assignedPhotographerIds'] ?? []),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventDateTime: (data['eventDateTime'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      requiredArrivalTimeOffsetMinutes: (data['requiredArrivalTimeOffsetMinutes'] as num?)?.toDouble() ?? 30.0,
      lateDeductionAmount: (data['lateDeductionAmount'] as num?)?.toDouble() ?? 0.0,
      gracePeriodMinutes: (data['gracePeriodMinutes'] as num?)?.toInt() ?? 10,
      status: data['status'] ?? 'scheduled',
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'assignedPhotographerIds': assignedPhotographerIds,
      'title': title,
      'description': description,
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'location': location,
      'requiredArrivalTimeOffsetMinutes': requiredArrivalTimeOffsetMinutes,
      'lateDeductionAmount': lateDeductionAmount,
      'gracePeriodMinutes': gracePeriodMinutes,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

