# cam_touch_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Functions

The `functions` directory contains Cloud Functions written in TypeScript.
After installing dependencies with `npm install` inside that folder, deploy
the functions using:

```bash
firebase deploy --only functions
```

You can verify that `processPhotographerCheckIn` runs by checking the
Firebase Console logs after creating an `attendance_records` document.


## Firestore Security Rules

The `firestore.rules` file contains development rules that allow any authenticated user to read and write all documents. Deploy these rules with:

```bash
firebase deploy --only firestore:rules
```

These permissive rules are intended for local testing. Review and tighten them before releasing the app.
