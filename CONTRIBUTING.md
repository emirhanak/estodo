# Contributing to estodo

Thanks for your interest in estodo. Please keep contributions focused,
reviewable, and free of personal task or account data.

## Local setup

1. Install the current stable Flutter SDK.
2. Create a separate Firebase project for development.
3. Copy `config/firebase.dev.example.json` to
   `config/firebase.dev.json` and enter your own Firebase client values.
4. Enable Email/Password and Anonymous authentication in Firebase.
5. Deploy the checked-in Firestore rules and indexes to your development
   project.
6. Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=config/firebase.dev.json
```

## Pull requests

- Describe the user problem and the behavior that changed.
- Add or update tests for behavior changes.
- Run `flutter analyze` and `flutter test` before opening the pull request.
- Do not commit Firebase production configuration, signing files, API keys,
  reviewer accounts, screenshots containing real tasks, or user information.
- Report security issues privately as described in `SECURITY.md`.
