import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Logs a recovered error and records it in Crashlytics as non-fatal.
///
/// Use this instead of an empty `catch` when the app can keep going but the
/// failure should still be visible. Safe to call before Firebase is ready.
void reportError(Object error, StackTrace? stack, {required String reason}) {
  debugPrint('$reason: $error');
  if (Firebase.apps.isEmpty) return;
  try {
    FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
  } catch (crashlyticsError) {
    debugPrint('Crashlytics unavailable: $crashlyticsError');
  }
}
