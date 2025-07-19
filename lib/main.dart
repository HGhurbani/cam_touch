// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // تأكد من هذا الاستيراد

import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart';
import 'firebase_options.dart';

// سجل دالة معالجة الإشعارات في الخلفية (يجب أن تكون خارج دالة main)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase might already be initialized when the app is running. Only
  // initialize if there are no existing Firebase apps to avoid the
  // [core/duplicate-app] exception.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint("Handling a background message: ${message.messageId}");
  // يمكنك القيام بمعالجة البيانات أو توجيه المستخدم إلى شاشة معينة هنا
}

Future<void> initializeFirebase() async {
  // Initialize Firebase for the current platform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background message handler for FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kDebugMode) {
    // Use debug providers to bypass app attestation during local development
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );

    // Skip phone number reCAPTCHA verification and SMS quotas in debug mode
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter widgets are initialized

  // Initialize Firebase and development utilities
  await initializeFirebase();

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
        Provider(create: (_) => LocationService()),
      ],
      child: const MyApp(),
    ),
  );
}