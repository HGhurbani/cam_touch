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

## Firebase Setup and Troubleshooting

This project uses **Firebase App Check**. If you see errors similar to:

```
Error getting App Check token; using placeholder token instead.
com.google.firebase.FirebaseException: Error returned from API. code: 403
```

make sure the **Firebase App Check API** is enabled for your project in the
[Google Cloud Console](https://console.developers.google.com/apis/api/firebaseappcheck.googleapis.com/overview).
It can take a few minutes after enabling for the changes to propagate.

When running in debug mode, a debug App Check provider is used. Add the debug
token printed in the Android logs to the *App Check* section of the Firebase
Console to avoid `Too many attempts` errors.
