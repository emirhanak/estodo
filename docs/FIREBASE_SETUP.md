# Firebase setup

Official references:

- Firebase Flutter setup: https://firebase.google.com/docs/flutter/setup
- FCM for Flutter: https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- Firestore security rules: https://firebase.google.com/docs/firestore/security/get-started

## 1. Create the Firebase project

1. Open Firebase Console and create a project.
2. Enable Authentication > Sign-in method > Email/Password and Anonymous.
3. Create Cloud Firestore in Native mode.
4. Enable Cloud Messaging. For iOS, upload the APNs authentication key from Apple Developer.
5. Add Android app with package name `com.estodo.app`.
6. Add iOS app with bundle identifier `com.estodo.app`.

## 2. Install tooling

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

## 3. Generate native Firebase config

Run from the project root:

```bash
flutterfire configure \
  --project your-firebase-project-id \
  --platforms android,ios \
  --android-package-name com.estodo.app \
  --ios-bundle-id com.estodo.app
```

This creates:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

The public repository keeps `lib/firebase_options.dart` environment-driven so
production identifiers are not embedded in source control. If FlutterFire
overwrites it, restore the tracked version and use the generated native files
with `--dart-define-from-file` as documented below.

The repository also includes an environment-driven `lib/firebase_options.dart`.
If you prefer not to overwrite it, copy `config/firebase.dev.example.json` to
`config/firebase.dev.json` and fill the values from Firebase Console.

Run with:

```bash
flutter run --dart-define-from-file=config/firebase.dev.json
```

## 4. Deploy rules and indexes

```bash
firebase use your-firebase-project-id
firebase deploy --only firestore:rules,firestore:indexes
```

## 5. FCM notes

Android 13+ notification permission is requested at runtime. Exact alarm
permission is requested for local reminders.

iOS push notifications require:

- APNs key uploaded to Firebase.
- Push Notifications capability enabled in Xcode.
- Background Modes > Remote notifications enabled.
- Production `aps-environment` value for App Store release.
- iOS 15.0 or later.
