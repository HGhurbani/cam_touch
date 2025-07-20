// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart'; // استيراد جديد لـ Dynamic Links
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/booking_model.dart';
import '../models/photographer_model.dart';
import '../models/event_model.dart';
import '../models/attendance_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseDynamicLinks _dynamicLinks = FirebaseDynamicLinks.instance; // تهيئة Dynamic Links

  // ------------------------------------
  // User Management (Collection: 'users')
  // ------------------------------------

  // الحصول على بيانات مستخدم واحد بناءً على UID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user $uid: $e');
      return null;
    }
  }

  // تحديث بيانات مستخدم
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint('Error updating user data for $uid: $e');
      rethrow;
    }
  }

  // إضافة نقاط لمستخدم
  Future<void> addPointsToUser(String uid, int pointsToAdd) async {
    try {
      await _db.collection('users').doc(uid).update({
        'points': FieldValue.increment(pointsToAdd),
      });
    } catch (e) {
      debugPrint('Error adding points to user $uid: $e');
      rethrow;
    }
  }

  // الحصول على قائمة بجميع العملاء
  Stream<List<UserModel>> getAllClients() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'client')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // ------------------------------------
  // Booking Management (Collection: 'bookings')
  // ------------------------------------

  // إنشاء طلب حجز جديد
  Future<String?> addBooking(BookingModel booking) async {
    try {
      DocumentReference docRef = await _db.collection('bookings').add(booking.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding booking: $e');
      return null;
    }
  }

  // الحصول على حجز واحد بناءً على ID
  Future<BookingModel?> getBooking(String bookingId) async {
    try {
      DocumentSnapshot doc = await _db.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return BookingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting booking $bookingId: $e');
      return null;
    }
  }

  // تحديث حجز
  Future<void> updateBooking(String bookingId, Map<String, dynamic> data) async {
    try {
      await _db.collection('bookings').doc(bookingId).update(data);
    } catch (e) {
      debugPrint('Error updating booking $bookingId: $e');
      rethrow;
    }
  }

  // حذف حجز
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _db.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      debugPrint('Error deleting booking $bookingId: $e');
      rethrow;
    }
  }

  // الحصول على جميع حجوزات عميل معين
  Stream<List<BookingModel>> getClientBookings(String clientId) {
    return _db
        .collection('bookings')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  // الحصول على جميع حجوزات مصور معين
  Stream<List<BookingModel>> getPhotographerBookings(String photographerId) {
    return _db
        .collection('bookings')
        .where('photographerIds', arrayContains: photographerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  // الحصول على جميع الحجوزات للمدير (مع إمكانية التصفية لاحقًا)
  Stream<List<BookingModel>> getAllBookings() {
    return _db
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  /// Retrieves all bookings that occur on the given [date].
  Stream<List<BookingModel>> getBookingsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection('bookings')
        .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('bookingDate', isLessThan: Timestamp.fromDate(end))
        .orderBy('bookingDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  // ------------------------------------
  // Photographer Management (Collection: 'photographers_data')
  // ------------------------------------

  // إضافة بيانات مصور جديد (تُستخدم عند أول مرة لتسجيل المصور أو إضافة تفاصيل إضافية)
  Future<void> addOrUpdatePhotographerData(PhotographerModel photographer) async {
    try {
      await _db.collection('photographers_data').doc(photographer.uid).set(photographer.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error adding/updating photographer data ${photographer.uid}: $e');
      rethrow;
    }
  }

  // الحصول على بيانات مصور واحد
  Future<PhotographerModel?> getPhotographerData(String photographerId) async {
    try {
      DocumentSnapshot doc = await _db.collection('photographers_data').doc(photographerId).get();
      if (doc.exists) {
        return PhotographerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting photographer data $photographerId: $e');
      return null;
    }
  }

  // الحصول على قائمة بجميع المصورين
  Stream<List<PhotographerModel>> getAllPhotographers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'photographer')
        .snapshots()
        .asyncMap((snapshot) async {
      return Future.wait(snapshot.docs.map((userDoc) async {
        try {
          final photographerSnap =
              await _db.collection('photographers_data').doc(userDoc.id).get();
          if (photographerSnap.exists) {
            return PhotographerModel.fromFirestore(photographerSnap);
          } else {
            return PhotographerModel(uid: userDoc.id);
          }
        } catch (e) {
          debugPrint('Error fetching photographer data for ${userDoc.id}: $e');
          return PhotographerModel(uid: userDoc.id);
        }
      }).toList());
    });
  }

  /// تسجيل دفعة لمصور لحجز معين وتحديث رصيده
  Future<void> recordPhotographerPayment(
      String bookingId, String photographerId, double amount) async {
    final bookingRef = _db.collection('bookings').doc(bookingId);
    final photographerRef =
        _db.collection('photographers_data').doc(photographerId);
    await _db.runTransaction((txn) async {
      // All reads should happen before any writes within the transaction.
      final bookingSnap = await txn.get(bookingRef);
      final photographerSnap = await txn.get(photographerRef);

      if (!bookingSnap.exists) {
        throw Exception('Booking not found');
      }

      final data = bookingSnap.data() as Map<String, dynamic>;
      final payments = Map<String, dynamic>.from(data['photographerPayments'] ?? {});
      final current = (payments[photographerId] as num?)?.toDouble() ?? 0.0;
      payments[photographerId] = current + amount;

      txn.update(bookingRef, {'photographerPayments': payments});

      if (photographerSnap.exists) {
        txn.update(photographerRef, {
          // reduce the remaining balance when a payment is made
          'balance': FieldValue.increment(-amount),
        });
      }
    });
  }

  // ------------------------------------
  // Event Management (Collection: 'events')
  // ------------------------------------

  // إضافة فعالية جديدة
  Future<String?> addEvent(EventModel event) async {
    try {
      DocumentReference docRef = await _db.collection('events').add(event.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding event: $e');
      return null;
    }
  }

  // الحصول على فعالية واحدة
  Future<EventModel?> getEvent(String eventId) async {
    try {
      DocumentSnapshot doc = await _db.collection('events').doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting event $eventId: $e');
      return null;
    }
  }

  // تحديث فعالية
  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    try {
      await _db.collection('events').doc(eventId).update(data);
    } catch (e) {
      debugPrint('Error updating event $eventId: $e');
      rethrow;
    }
  }

  // الحصول على فعاليات مصور معين
  Stream<List<EventModel>> getPhotographerEvents(String photographerId) {
    return _db
        .collection('events')
        .where('assignedPhotographerIds', arrayContains: photographerId)
        .orderBy('eventDateTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // الحصول على جميع الفعاليات (للمدير)
  Stream<List<EventModel>> getAllEvents() {
    return _db
        .collection('events')
        .orderBy('eventDateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // ------------------------------------
  // Attendance Management (Collection: 'attendance_records')
  // ------------------------------------

  /// Adds a new attendance record to the `attendance_records` collection.
  ///
  /// Returns the generated document ID if the operation succeeds or `null`
  /// if an exception is thrown.
  Future<String?> addAttendanceRecord(AttendanceModel record) async {
    try {
      final DocumentReference docRef =
          await _db.collection('attendance_records').add(record.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding attendance record: $e');
      return null;
    }
  }

  /// Retrieves a real-time stream of attendance records for a photographer
  /// associated with a specific event.
  Stream<List<AttendanceModel>> getPhotographerAttendanceForEvent(
      String photographerId, String eventId) {
    return _db
        .collection('attendance_records')
        .where('photographerId', isEqualTo: photographerId)
        .where('eventId', isEqualTo: eventId)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList());
  }

  /// Retrieves a real-time stream of all attendance records ordered by time.
  Stream<List<AttendanceModel>> getAllAttendanceRecords() {
    return _db
        .collection('attendance_records')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList());
  }

  // ------------------------------------
  // Referral System
  // ------------------------------------

  // إنشاء رابط إحالة ديناميكي
  Future<String?> createReferralLink(String userId) async {
    try {
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        uriPrefix: 'https://camtouch.page.link',
        link: Uri.parse('https://camtouch.com/referral?referredBy=$userId'),
        androidParameters: const AndroidParameters(
          packageName: 'com.cam.touch.cam_touch_app',
          minimumVersion: 1,
        ),
        iosParameters: const IOSParameters(
          bundleId: 'com.cam.touch.camTouchApp',
          minimumVersion: '1.0.0',
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: 'Cam Touch: حجز جلسات تصوير احترافية!',
          description: 'انضم إلينا واحصل على مكافآت عند التسجيل عبر هذا الرابط!',
          imageUrl: Uri.parse('https://your-app-logo.com/logo.png'), // استبدل بشعار تطبيقك
        ),
      );

      final ShortDynamicLink shortDynamicLink = await _dynamicLinks.buildShortLink(parameters);
      final Uri shortUrl = shortDynamicLink.shortUrl;

      // حفظ الرابط في مستند المستخدم
      await updateUserData(userId, {'referralLink': shortUrl.toString()});
      return shortUrl.toString();
    } catch (e) {
      debugPrint('Error creating dynamic link: $e');
      return null;
    }
  }

  // ------------------------------------
  // General Utility Functions
  // ------------------------------------

  // توليد ID عشوائي لمستند Firestore (يمكن استخدامه قبل إضافة المستند)
  String randomDocumentId() {
    return _db.collection('temp').doc().id;
  }

  // يمكن إضافة دوال عامة مثل الحصول على مستند باستخدام reference
  Future<DocumentSnapshot> getDocumentById(String collection, String docId) async {
    return _db.collection(collection).doc(docId).get();
  }
}