// lib/core/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تهيئة الإشعارات عند بدء التطبيق
  Future<void> initialize() async {
    // طلب الإذن بالإشعارات (iOS/Web)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission for notifications');
      _getToken(); // الحصول على الرمز المميز للجهاز
      _setupForegroundMessaging(); // معالجة الإشعارات الأمامية
    } else {
      debugPrint('User denied permission for notifications');
    }
  }

  // الحصول على رمز الجهاز المميز (FCM Token) وحفظه في Firestore
  Future<void> _getToken() async {
    String? token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');
    // يمكنك حفظ هذا الرمز المميز في Firestore لمستخدم معين
    // مثلاً، في مستند المستخدم الخاص به:
    // String? userId = FirebaseAuth.instance.currentUser?.uid;
    // if (userId != null && token != null) {
    //   await _firestore.collection('users').doc(userId).update({'fcmToken': token});
    // }
  }

  // معالجة الإشعارات عند وصولها والتطبيق في المقدمة
  void _setupForegroundMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // يمكنك عرض إشعار مخصص هنا (مثل باستخدام flutter_local_notifications)
        // For now, just print
      }
    });
  }

  // إرسال إشعار لمستخدم معين (هذه الوظيفة ستُستدعى من Cloud Function لاحقاً)
  // لا يمكن للتطبيق العميل إرسال إشعارات مباشرة إلى أجهزة أخرى لأسباب أمنية.
  // بدلاً من ذلك، سترسل طلب إلى Cloud Function، التي بدورها ترسل الإشعار.
  // لذلك، هذه الدالة هنا هي مجرد مكان لوضع المنطق المستقبلي إذا كان هناك وسيط خادم.
  Future<void> sendNotificationToUser(String userId, String title, String body) async {
    debugPrint('Attempting to send notification to user $userId: $title - $body');
    // منطق إرسال الإشعار هنا سيتضمن استدعاء Cloud Function
    // مثال (افتراضي):
    // await _firestore.collection('notificationRequests').add({
    //   'userId': userId,
    //   'title': title,
    //   'body': body,
    //   'timestamp': FieldValue.serverTimestamp(),
    // });
  }

  // معالجة الإشعارات عند النقر عليها (والتطبيق في الخلفية/مغلق)
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // تأكد من تهيئة Firebase هنا إذا لم يكن التطبيق قيد التشغيل بالفعل
    await Firebase.initializeApp();
    debugPrint("Handling a background message: ${message.messageId}");
    // يمكنك القيام بمعالجة البيانات أو توجيه المستخدم إلى شاشة معينة
  }
}