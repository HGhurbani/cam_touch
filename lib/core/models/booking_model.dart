// lib/core/models/booking_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id; // Booking ID (Firestore Document ID)
  final String clientId;
  final String? photographerId; // قد يكون null في البداية
  final List<String>? photographerIds; // دعم تعيين أكثر من مصور
  final String clientName;
  final String clientEmail;
  final DateTime bookingDate;
  final String bookingTime; // مثلاً "10:00 AM" أو "14:30"
  final String location;
  final String serviceType; // مثلاً "تصوير حفلات", "تصوير منتجات"
  final double estimatedCost;
  // 'pending_admin_approval', 'approved', 'rejected',
  // 'deposit_paid', 'completed', 'cancelled', 'scheduled'
  final String status;
  final double? depositAmount; // مبلغ العربون المطلوب
  final String? paymentProofUrl; // رابط صورة إثبات الدفع
  final String? invoiceUrl; // رابط الفاتورة
  final double paidAmount; // اجمالي المبلغ المدفوع
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  BookingModel({
    required this.id,
    required this.clientId,
    this.photographerId,
    this.photographerIds,
    required this.clientName,
    required this.clientEmail,
    required this.bookingDate,
    required this.bookingTime,
    required this.location,
    required this.serviceType,
    required this.estimatedCost,
    required this.status,
    this.paidAmount = 0.0,
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
      photographerIds: (data['photographerIds'] as List?)?.map((e) => e.toString()).toList(),
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
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'photographerId': photographerId,
      'photographerIds': photographerIds,
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
      'paidAmount': paidAmount,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(), // يتم تحديثه عند كل تعديل
    };
  }

  BookingModel copyWith({
    String? clientId,
    String? photographerId,
    List<String>? photographerIds,
    String? clientName,
    String? clientEmail,
    DateTime? bookingDate,
    String? bookingTime,
    String? location,
    String? serviceType,
    double? estimatedCost,
    String? status,
    double? depositAmount,
    String? paymentProofUrl,
    String? invoiceUrl,
    double? paidAmount,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return BookingModel(
      id: id,
      clientId: clientId ?? this.clientId,
      photographerId: photographerId ?? this.photographerId,
      photographerIds: photographerIds ?? this.photographerIds,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      location: location ?? this.location,
      serviceType: serviceType ?? this.serviceType,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      status: status ?? this.status,
      depositAmount: depositAmount ?? this.depositAmount,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      invoiceUrl: invoiceUrl ?? this.invoiceUrl,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}