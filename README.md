# Cam Touch App

<div align="right">
تطبيق Flutter احترافي يربط العملاء بالمصورين، مع دعم إدارة الحجوزات، الإشعارات، التخزين السحابي، وميزات Firebase المتقدمة.
</div>

## ✨ Overview

**Cam Touch** هو مشروع Flutter يعتمد على Firebase لتقديم تجربة متكاملة لإدارة خدمات التصوير، من التسجيل والمصادقة إلى تخزين الملفات والإشعارات.

### المزايا الرئيسية

- 🔐 **Authentication** عبر Firebase Auth.
- 🗂️ **Cloud Firestore** لإدارة بيانات التطبيق.
- ☁️ **Firebase Storage** لرفع وحفظ الملفات (مثل الفواتير والمرفقات).
- 🔔 **Push Notifications** عبر Firebase Messaging.
- 🧭 **Maps & Location** باستخدام Google Maps و Geolocator.
- 📄 **PDF Generation** لإنشاء وطباعة المستندات.
- 🌍 **Localization-ready** مع `flutter_localizations`.

---

## 🧱 Tech Stack

- **Framework:** Flutter (Dart)
- **Backend Services:** Firebase (Auth, Firestore, Functions, Storage, Messaging, Dynamic Links)
- **State Management:** Provider
- **Maps & GPS:** google_maps_flutter + geolocator

---

## 📁 Project Structure

```text
cam_touch/
├── lib/                 # Flutter app source code
├── assets/              # Images and fonts
├── functions/           # Firebase Cloud Functions (TypeScript)
├── firestore.rules      # Firestore security rules
├── ios/ / android/      # Platform-specific setup
└── pubspec.yaml         # Dependencies and Flutter configuration
```

---

## 🚀 Quick Start

### 1) Prerequisites

تأكد من توفر الأدوات التالية:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (عادةً يأتي مع Flutter)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- حساب Firebase ومشروع مفعل

### 2) Install dependencies

```bash
flutter pub get
```

### 3) Configure Firebase

- أضف ملفات إعداد Firebase الخاصة بكل منصة (Android / iOS).
- تأكد من تفعيل الخدمات المستخدمة (Auth, Firestore, Storage, Messaging, Functions).

### 4) Run the app

```bash
flutter run
```

---

## ☁️ Firebase Cloud Functions

مجلد `functions/` يحتوي على Cloud Functions مكتوبة بـ TypeScript.

### تثبيت واعتماد الحزم

```bash
cd functions
npm install
```

### النشر

```bash
firebase deploy --only functions
```

### التحقق

يمكن التحقق من تشغيل `processPhotographerCheckIn` عبر **Firebase Console Logs** بعد إنشاء مستند في `attendance_records`.

---

## 🔒 Firestore Security Rules

ملف `firestore.rules` يحتوي على قواعد تطوير (Development Rules) تسمح لأي مستخدم موثّق بالقراءة والكتابة.

لنشر القواعد:

```bash
firebase deploy --only firestore:rules
```

> ⚠️ **تنبيه أمني:** القواعد الحالية مناسبة للتجارب والتطوير فقط. يجب تشديد القواعد قبل الإطلاق في بيئة الإنتاج.

---

## 🧪 Useful Commands

```bash
# تحليل الشيفرة
flutter analyze

# تشغيل الاختبارات
flutter test

# بناء نسخة إصدار (مثال Android)
flutter build apk --release
```

---

## 🤝 Contributing

المساهمات مرحب بها! لاقتراح تحسينات:

1. اعمل Fork للمشروع
2. أنشئ فرعًا جديدًا
3. نفّذ التعديلات مع وصف واضح
4. افتح Pull Request

---

## 📄 License

لا يوجد ترخيص محدد حاليًا. يُفضّل إضافة ملف `LICENSE` لتوضيح شروط الاستخدام وإعادة التوزيع.
