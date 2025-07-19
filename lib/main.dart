// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // تأكد من هذا الاستيراد

import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart'; // استيراد جديد
import 'firebase_options.dart';

// سجل دالة معالجة الإشعارات في الخلفية (يجب أن تكون خارج دالة main)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
  // يمكنك القيام بمعالجة البيانات أو توجيه المستخدم إلى شاشة معينة هنا
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter widgets are initialized

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // سجل دالة معالجة الخلفية لـ FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // تهيئة NotificationService
  final notificationService = NotificationService();
  await notificationService.initialize(); // طلب الأذونات والحصول على الرمز المميز

  // Set preferred orientations for the app
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
        Provider(create: (_) => notificationService),
        Provider(create: (_) => LocationService()), // أضف LocationService هنا
      ],
      child: const MyApp(),
    ),
  );
}