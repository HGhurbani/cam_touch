# Cam Touch App

A professional Flutter application that connects clients with photographers, with support for booking management, notifications, cloud storage, and advanced Firebase features.

## ✨ Overview

**Cam Touch** is a Flutter project built on Firebase to provide a complete workflow for photography services, from registration and authentication to file storage and notifications.

### Key Features

- 🔐 **Authentication** via Firebase Auth.
- 🗂️ **Cloud Firestore** for application data management.
- ☁️ **Firebase Storage** for uploading and storing files (such as invoices and attachments).
- 🔔 **Push Notifications** via Firebase Messaging.
- 🧭 **Maps & Location** using Google Maps and Geolocator.
- 📄 **PDF Generation** to create and print documents.
- 🌍 **Localization-ready** with `flutter_localizations`.

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

Make sure you have the following tools installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (usually included with Flutter)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- An active Firebase account and project

### 2) Install dependencies

```bash
flutter pub get
```

### 3) Configure Firebase

- Add Firebase configuration files for each platform (Android / iOS).
- Make sure the required services are enabled (Auth, Firestore, Storage, Messaging, Functions).

### 4) Run the app

```bash
flutter run
```

---

## ☁️ Firebase Cloud Functions

The `functions/` folder contains Cloud Functions written in TypeScript.

### Install dependencies

```bash
cd functions
npm install
```

### Deploy

```bash
firebase deploy --only functions
```

### Verification

You can verify that `processPhotographerCheckIn` is running through **Firebase Console Logs** after creating a document in `attendance_records`.

---

## 🔒 Firestore Security Rules

The `firestore.rules` file currently contains development rules that allow any authenticated user to read and write.

To deploy the rules:

```bash
firebase deploy --only firestore:rules
```

> ⚠️ **Security Notice:** The current rules are suitable for development and testing only. You should harden them before launching to production.

---

## 🧪 Useful Commands

```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Build release version (Android example)
flutter build apk --release
```

---

## 🤝 Contributing

Contributions are welcome! To suggest improvements:

1. Fork the repository
2. Create a new branch
3. Implement your changes with a clear description
4. Open a Pull Request

---

## 📄 License

No specific license is currently defined. It is recommended to add a `LICENSE` file to clarify usage and redistribution terms.
