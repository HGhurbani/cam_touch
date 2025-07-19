import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Placeholder Firebase configuration. Replace with real values for production.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAiImC58YZKweIvgnHv8TBesdTiC5i6Cwk',
    appId: '1:1058080841852:web:d268ba06cf1485ad0669f9',
    messagingSenderId: '1058080841852',
    projectId: 'kisko-jump',
    authDomain: 'kisko-jump.firebaseapp.com',
    storageBucket: 'kisko-jump.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAK2zpkft3iF8FSdHoO2n32KyMGQBkaM9w',
    appId: '1:1058080841852:android:63584a43056e0cf10669f9',
    messagingSenderId: '1058080841852',
    projectId: 'kisko-jump',
    storageBucket: 'kisko-jump.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    iosBundleId: 'com.yourcompany.camtouchApp',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    iosBundleId: 'com.yourcompany.camtouchApp',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );
}
