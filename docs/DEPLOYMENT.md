# Deployment

## Android

Package name: `com.estodo.app`

Versioning is controlled by `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

### Signing

Create a release keystore:

```bash
keytool -genkey -v -keystore android/app/estodo-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias estodo
```

Create `android/key.properties`:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=estodo
storeFile=app/estodo-release.jks
```

Build:

```bash
flutter build appbundle --release --dart-define-from-file=config/firebase.prod.json
flutter build apk --release --dart-define-from-file=config/firebase.prod.json
```

Run icon and splash generation before release:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### Play Store checklist

- App bundle uploaded from `build/app/outputs/bundle/release/app-release.aab`.
- Privacy Policy URL added.
- Data safety form declares account info, user content, diagnostics, and device IDs if FCM/Analytics are enabled.
- Exact alarm declaration reviewed if you keep `SCHEDULE_EXACT_ALARM` for reminders.
- Notification permission behavior tested on Android 13+.
- Firestore rules deployed to production.
- Crashlytics receiving release symbols.

## iOS

Bundle identifier: `com.estodo.app`

App Store uploads require a Mac with the currently accepted Xcode and iOS SDK.
As of July 2026, use Xcode 26 or later with an iOS 26 SDK.

Open the workspace:

```bash
open ios/Runner.xcworkspace
```

In Xcode:

- Set Team and signing certificate.
- Set Bundle Identifier to `com.estodo.app`.
- Enable Push Notifications.
- Enable Background Modes > Remote notifications.
- Set `aps-environment` to `production` for release.
- Confirm `GoogleService-Info.plist` is included in Runner target.
- Confirm Email/Password and Anonymous sign-in are enabled in Firebase Auth.

Build:

```bash
flutter build ipa --release --dart-define-from-file=config/firebase.prod.json
```

### App Store checklist

- Archive validates in Xcode Organizer.
- App Privacy declares account info, user content, identifiers, diagnostics, and notifications.
- Production APNs key uploaded to Firebase.
- Sign in/register flow works on TestFlight.
- Offline create/edit/delete sync tested by toggling network.
- Reminder notifications tested on a physical device.
