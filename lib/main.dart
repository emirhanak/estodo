import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences? prefs;
  ThemeMode initialThemeMode = ThemeMode.system;
  bool initialOled = false;
  Color initialAccent = AppTheme.seed;

  try {
    prefs = await Bootstrap.initialize();
    final stored =
        Hive.box(AppConstants.settingsBox).get('themeMode') as String?;
    initialThemeMode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    initialOled = prefs.getBool('pref.oled_black_mode') ?? false;
    final accentVal = prefs.getInt('pref.accent_color');
    if (accentVal != null) initialAccent = Color(accentVal);
  } catch (_) {}

  runZonedGuarded(
    () => runApp(
      BootstrapApp(
        initialPrefs: prefs,
        initialThemeMode: initialThemeMode,
        initialOled: initialOled,
        initialAccent: initialAccent,
      ),
    ),
    (error, stack) {
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}
