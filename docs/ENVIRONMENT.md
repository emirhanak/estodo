# Environment and configuration

The app supports two Firebase configuration styles.

## FlutterFire generated config

Recommended for most teams:

```bash
flutterfire configure --platforms android,ios
flutter run
```

## Dart defines

Use this when CI/CD injects configuration at build time.

1. Copy `config/firebase.dev.example.json` to `config/firebase.dev.json`.
2. Fill values from Firebase Console > Project settings > General.
3. Run:

```bash
flutter run --dart-define-from-file=config/firebase.dev.json
```

Production build:

```bash
flutter build appbundle --release --dart-define-from-file=config/firebase.prod.json
flutter build ipa --release --dart-define-from-file=config/firebase.prod.json
```

Do not commit real production config files if your organization treats Firebase
app IDs or API keys as internal metadata. Firebase API keys are not database
secrets; Firestore security rules are the actual enforcement boundary.
