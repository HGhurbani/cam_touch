// lib/core/models/booking_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id; // Booking ID (Firestore Document ID)
  final String clientId;
  final String? photographerId; // قد يكون null في البداية
  final String clientName;
  final String clientEmail;
  final DateTime bookingDate;
  final String bookingTime; // مثلاً "10:00 AM" أو "14:30"
  final String location;
  final String serviceType; // مثلاً "تصوير حفلات", "تصوير منتجات"
  final double estimatedCost;
  final String status; // 'pending_admin_approval', 'approved', 'rejected', 'deposit_paid', 'completed', 'cancelled'
  final double? depositAmount; // مبلغ العربون المطلوب
  final String? paymentProofUrl; // رابط صورة إثبات الدفع
  final String? invoiceUrl; // رابط الفاتورة
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  BookingModel({
    required this.id,
    required this.clientId,
    this.photographerId,
    required this.clientName,
    required this.clientEmail,
    required this.bookingDate,
    required this.bookingTime,
    required this.location,
    required this.serviceType,
    required this.estimatedCost,
    required this.status,
    this.depositAmount,
    this.paymentProofUrl,
    this.invoiceUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      photographerId: data['photographerId'],
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      bookingTime: data['bookingTime'] ?? '',
      location: data['location'] ?? '',
      serviceType: data['serviceType'] ?? '',
      estimatedCost: (data['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending_admin_approval',
      depositAmount: (data['depositAmount'] as num?)?.toDouble(),
      paymentProofUrl: data['paymentProofUrl'],
      invoiceUrl: data['invoiceUrl'],
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'photographerId': photographerId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'bookingTime': bookingTime,
      'location': location,
      'serviceType': serviceType,
      'estimatedCost': estimatedCost,
      'status': status,
      'depositAmount': depositAmount,
      'paymentProofUrl': paymentProofUrl,
      'invoiceUrl': invoiceUrl,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(), // يتم تحديثه عند كل تعديل
    };
  }
}