# Public repository checklist

A public GitHub repository exposes every committed file and its reachable Git
history. Files that must stay private cannot be committed to the public branch.

## Files that must remain private

- `config/firebase.dev.json`
- `config/firebase.prod.json`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `android/key.properties`
- Android `.jks` and `.keystore` files
- Apple `.p8`, `.p12`, and `.mobileprovision` files
- App Store Connect API keys and service-account JSON files

The repository `.gitignore` excludes these paths. Firebase client identifiers
are not server credentials, but this project still injects them at build time so
the public repository does not point contributors at the production backend.

## Before making the repository public

1. Confirm the included MIT License remains the intended license. It allows
   reuse, modification, redistribution, and commercial use.
2. Review the complete Git history for old credentials. Removing a secret from
   the latest commit does not remove it from earlier commits.
3. Rotate any credential that has ever been committed.
4. Confirm `git status --ignored` shows production configuration and signing
   files as ignored.
5. Run a secret scanner against the full history.
6. Keep the production Firebase project under owner-only access and deploy the
   checked-in Firestore rules.
7. Enable Firebase App Check before the public launch to reduce abuse of the
   production backend.
8. Add repository screenshots only after removing personal tasks, names,
   emails, meeting information, and notification content.
9. Use GitHub Issues for public bug reports, but never ask users to post private
   task data or account identifiers.

## Suggested public repository contents

Publish source code, tests, architecture documentation, example configuration,
privacy policies, screenshots with synthetic data, and build instructions.
Keep signing assets, production configuration, reviewer credentials, user data,
and App Store Connect credentials outside GitHub.
