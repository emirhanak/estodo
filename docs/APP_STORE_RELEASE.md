# App Store release runbook

This document is the release checklist for the first public iOS version of
estodo. Never commit certificates, provisioning profiles, APNs keys, Firebase
native configuration files, or production Dart-define files.

## 1. Join the Apple Developer Program

The lowest-cost option currently shown in Türkiye is enrollment from the Apple
Developer app as an annual auto-renewing subscription.

1. Install Apple Developer on an iPhone, iPad, or supported Mac.
2. Enable two-factor authentication on the Apple Account and sign in to iCloud.
3. Open Account > Enroll Now.
4. Complete identity verification using a government-issued photo ID.
5. Select Individual unless a registered legal entity with a D-U-N-S number
   should appear as the seller.
6. Accept the agreement and purchase the annual membership.

For an Individual membership, the legal personal name appears as the App Store
seller. A brand or company seller name requires an Organization membership.

## 2. Prepare Apple and Firebase identifiers

1. In Certificates, Identifiers & Profiles, register the explicit Bundle ID
   `com.estodo.app`.
2. Enable Push Notifications for that identifier.
3. Create an APNs authentication key and download its `.p8` file once.
4. In Firebase Console, register an iOS app using `com.estodo.app`.
5. Upload the APNs key to Firebase Cloud Messaging.
6. Enable Email/Password and Anonymous providers in Firebase Authentication.
7. Download `GoogleService-Info.plist` to `ios/Runner/`. It is intentionally
   ignored by Git.
8. Deploy `firestore.rules` and `firestore.indexes.json` to the production
   Firebase project.

## 3. Create private production configuration

Copy `config/firebase.dev.example.json` to `config/firebase.prod.json`, fill in
the production Firebase values, and keep the file local. Confirm that the iOS
bundle ID is `com.estodo.app`.

## 4. Configure the Codemagic build

The first TestFlight build is produced on Codemagic, so a local Mac is not
required. The repository contains `codemagic.yaml`; signing files and Firebase
configuration stay encrypted in Codemagic and are never committed.

1. Connect only the `emirhanak/estodo` repository to Codemagic.
2. In App Store Connect, create a dedicated API key named
   `estodo-app-store` with the App Manager role.
3. Add the key in Codemagic under Developer Portal integrations using the same
   name: `estodo-app-store`.
4. Generate or fetch an Apple Distribution certificate and an App Store
   provisioning profile for `com.estodo.app`.
5. Create a Codemagic environment variable group named `estodo_firebase`.
6. Add `FIREBASE_DART_DEFINES_B64`, containing the Base64-encoded
   `config/firebase.prod.json`, as a Secret variable.
7. Add `IOS_FIREBASE_SECRET`, containing the complete
   `GoogleService-Info.plist`, as a Secret variable.
8. Start the `estodo iOS - TestFlight` workflow manually.

Codemagic runs analysis and tests, builds a signed IPA, and uploads it to App
Store Connect. The workflow intentionally does not submit the app to App Store
review automatically.

## 5. Test later on a Mac

Use a compatible MacBook for later native iOS development and device testing.

1. Install current stable Flutter, CocoaPods, and Xcode.
2. Open `ios/Runner.xcworkspace`, not `Runner.xcodeproj`.
3. Select Runner > Signing & Capabilities and choose the Apple Developer team.
4. Confirm Bundle Identifier is `com.estodo.app` and Automatically manage
   signing is enabled.
5. Confirm Push Notifications and Background Modes > Remote notifications are
   enabled.
6. Run on a physical iPhone and test registration, guest access, task sync,
   offline editing, reminders, password reset, and account deletion.
7. Run:

```bash
flutter pub get
cd ios && pod install && cd ..
flutter analyze
flutter test
flutter build ipa --release --dart-define-from-file=config/firebase.prod.json
```

The IPA is generated under `build/ios/ipa/`.

## 6. Create the App Store Connect record

Create a new iOS app before uploading the IPA:

- Name: `estodo: Görev Listesi`
- Primary language: Turkish
- Bundle ID: `com.estodo.app`
- SKU: `estodo-ios-001`
- Primary category: Productivity
- Price: Free

The exact app name is confirmed only when App Store Connect accepts the new app
record. Add an English localization after creating the Turkish record.

## 7. Complete product and privacy information

Provide final, publicly accessible URLs without placeholders:

- Privacy policy URL
- Support URL
- Account deletion/help URL

After the clean public repository is published as `emirhanak/estodo` on its
`main` branch, the following URLs can be used:

- Privacy: `https://github.com/emirhanak/estodo/blob/main/PRIVACY_POLICY.md`
- Support: `https://github.com/emirhanak/estodo/blob/main/docs/index.md`
- Account deletion: `https://github.com/emirhanak/estodo/blob/main/docs/ACCOUNT_DELETION.md`

Complete the current age-rating questionnaire and App Privacy answers. estodo
uses Firebase Authentication, Firestore, Analytics, Crashlytics, and Cloud
Messaging, so the answers must include account/contact information, user task
content, identifiers, usage data, and diagnostics as applicable.

Upload real iPhone screenshots showing:

1. My Day
2. A meeting or work list
3. Task details and reminder setup
4. Planned tasks
5. Dark mode

Screenshots and descriptions must match the submitted build.

## 8. TestFlight and review

1. Upload the IPA using the Codemagic workflow.
2. Wait for processing and resolve export-compliance questions.
3. Test the build with TestFlight on at least one physical iPhone.
4. Create a dedicated reviewer account containing sample tasks and provide its
   credentials in App Review Information.
5. Explain in Review Notes that cloud accounts sync tasks between devices and
   that guest access is available without registration.
6. Select the processed build, add it for review, and submit.

Do not upload a build until every backend service and public URL is live.
