# estodo

estodo is an open-source Flutter task manager for planning days, meetings, and
personal work. It uses Clean
Architecture, Riverpod, Hive, Firebase Auth, Cloud Firestore, Firebase Cloud
Messaging, local notifications, dark mode, and offline-first Firestore sync.

[![Flutter CI](https://github.com/emirhanak/estodo/actions/workflows/ci.yml/badge.svg)](https://github.com/emirhanak/estodo/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Project structure

```text
.
├── android/                         # Android package, permissions, signing, proguard
├── assets/branding/                 # App icon and splash source assets
├── config/firebase.dev.example.json # Dart-define Firebase template
├── docs/
│   ├── DEPLOYMENT.md
│   ├── ENVIRONMENT.md
│   ├── FIREBASE_SETUP.md
│   └── FIRESTORE_STRUCTURE.md
├── firestore.rules
├── firestore.indexes.json
├── ios/                             # iOS plist, app delegate, entitlements template
├── lib/
│   ├── app/                         # App shell and theme
│   ├── core/                        # Constants, bootstrap, Firebase/notification services
│   ├── features/auth/               # Auth data/domain/presentation
│   ├── features/settings/           # Theme and app settings
│   ├── features/tasks/              # Tasks/lists data/domain/presentation
│   ├── firebase_options.dart
│   └── main.dart
├── pubspec.yaml
└── firebase.json
```

## Features

- Email/password accounts, password-free guest access, and persistent sessions.
- Create, edit, delete, complete, prioritize, star, and schedule tasks.
- Custom lists with create, rename, delete.
- My Day with date-key reset logic.
- Important and Completed archive views.
- Search across tasks, notes, and list names.
- Local reminder notifications and FCM token registration.
- Firestore offline persistence plus Hive startup cache.
- System/light/dark theme toggle.

## First run

Install Flutter stable, Android Studio/Xcode toolchains, Firebase CLI, and
FlutterFire CLI.

If this repository was created without Flutter installed on the current machine,
refresh native wrapper files once:

```bash
flutter create . --platforms android,ios --org com.estodo --project-name estodo
```

Then install packages and configure Firebase:

```bash
flutter pub get
flutterfire configure \
  --project your-firebase-project-id \
  --platforms android,ios \
  --android-package-name com.estodo.app \
  --ios-bundle-id com.estodo.app
firebase deploy --only firestore:rules,firestore:indexes
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter run
```

Alternative run with Dart defines:

```bash
cp config/firebase.dev.example.json config/firebase.dev.json
flutter run --dart-define-from-file=config/firebase.dev.json
```

## Build commands

```bash
flutter analyze
flutter test
flutter build apk --release --dart-define-from-file=config/firebase.prod.json
flutter build appbundle --release --dart-define-from-file=config/firebase.prod.json
flutter build ipa --release --dart-define-from-file=config/firebase.prod.json
```

Detailed Firebase setup is in `docs/FIREBASE_SETUP.md`.
Deployment checklists are in `docs/DEPLOYMENT.md`.
The App Store release runbook is in `docs/APP_STORE_RELEASE.md`.
The public-repository checklist is in `docs/OPEN_SOURCE_RELEASE.md`.

## Privacy and security

Production Firebase configuration, Android/iOS signing assets, App Store
credentials, and user data are intentionally excluded from this repository.
See the [privacy policy](PRIVACY_POLICY.md), [account deletion guide](docs/ACCOUNT_DELETION.md),
and [security policy](SECURITY.md).

## License

estodo is available under the [MIT License](LICENSE).
