# Deployment

## Firestore schema releases

Deploy the repository's rules before distributing builds that write new task
fields. Codemagic builds the app; it does not deploy Firestore rules.

```bash
firebase deploy --only firestore:rules --project estodo-app
```

Run the planned screen smoke test on an Android emulator with a dedicated guest
account. It drives the actual title → Continue → Create flow, waits for the real
backend, reads the saved document directly from the server, and reopens the app
screen to check that the entry remains visible.

```bash
flutter test integration_test/planned_live_test.dart -d emulator-5554 --dart-define-from-file=config/firebase.prod.json
flutter test integration_test/planned_live_test.dart -d emulator-5554 --dart-define-from-file=config/firebase.prod.json --dart-define=TEST_HABIT=true
```

Use `--dart-define=EXPECT_REJECTED=true` only when deliberately testing rejected
writes against a restrictive test ruleset. That mode checks that the local entry
survives rejection and reopening even though no server document is created.

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

## TestFlight via Codemagic

`codemagic.yaml` holds one workflow, `ios-testflight`. It builds a signed IPA on a
Codemagic Mac and uploads it to TestFlight. App Store submission stays manual:
`submit_to_app_store` is `false`.

### One-time setup

1. **App Store Connect API key.** In App Store Connect go to Users and Access >
   Integrations > App Store Connect API and create a key with the App Manager
   role. Download the `.p8` once and note the Issuer ID and Key ID.
2. **Codemagic integration.** In Codemagic go to Teams > your team > Integrations
   > App Store Connect and add the key. Name it exactly `estodo-app-store` —
   that name is what `integrations.app_store_connect` refers to.
3. **Signing.** Codemagic > app settings > Code signing identities. With the API
   key in place, `ios_signing.distribution_type: app_store` lets Codemagic fetch
   or create the App Store provisioning profile for `com.estodo.app` itself.
4. **Secret environment group.** Create the group `estodo_firebase` with two
   secret variables:
   - `FIREBASE_DART_DEFINES_B64` — `base64 -i config/firebase.prod.json`
   - `IOS_FIREBASE_SECRET` — the contents of `ios/Runner/GoogleService-Info.plist`
5. **App id.** Add `APP_STORE_APP_ID` to the `estodo_firebase` group with the
   numeric Apple ID from App Store Connect > App Information. It is not a secret.
   The build-number step reads the last uploaded TestFlight build for that id and
   increments it, so a build is never rejected for reusing a number.
6. **App record.** The app must already exist in App Store Connect with the
   bundle identifier `com.estodo.app`. Codemagic uploads a build, it does not
   create the app.

### Releasing

The workflow triggers on a pushed tag matching `v*`:

```bash
# bump `version:` in pubspec.yaml first — the build name comes from it
git tag v1.0.0
git push origin v1.0.0
```

Or press **Start new build** in Codemagic and pick the `ios-testflight` workflow.

`flutter analyze` and `flutter test` run before the build, so a failing test stops
the release. Processing on Apple's side takes a few minutes after upload; internal
testers then see the build with no beta review. External test groups need
`beta_groups` uncommented, and those do go through Apple's beta review.
