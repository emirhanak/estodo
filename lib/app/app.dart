import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/services/bootstrap.dart';
import '../core/services/preferences_provider.dart';
import '../core/services/notification_provider.dart';
import '../firebase_options.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/auth_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/presentation/providers/theme_mode_provider.dart';
import '../features/tasks/presentation/screens/home_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'widgets/animated_splash_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({
    super.key,
    this.initialPrefs,
    this.initialThemeMode,
    this.initialOled,
    this.initialAccent,
  });

  final SharedPreferences? initialPrefs;
  final ThemeMode? initialThemeMode;
  final bool? initialOled;
  final Color? initialAccent;

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  ProviderContainer? _container;
  Object? _error;

  late ThemeMode _themeMode = widget.initialThemeMode ?? ThemeMode.system;
  late bool _oledMode = widget.initialOled ?? false;
  late Color _accent = widget.initialAccent ?? AppTheme.seed;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final prefs = widget.initialPrefs ?? await Bootstrap.initialize();

      // If theme was not passed initially, resolve it now from Hive/prefs
      if (widget.initialThemeMode == null) {
        final stored = Hive.box(AppConstants.settingsBox).get('themeMode') as String?;
        final resolvedMode = switch (stored) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        final oled = prefs.getBool('pref.oled_black_mode') ?? false;
        final accentVal = prefs.getInt('pref.accent_color');
        if (mounted) {
          setState(() {
            _themeMode = resolvedMode;
            _oledMode = oled;
            if (accentVal != null) _accent = Color(accentVal);
          });
        }
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Create container pre-warmed with SharedPreferences so all preference
      // providers return immediate, synchronous values with zero frame flicker.
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWith((ref) => prefs),
        ],
      );

      // Initialize notifications in background without blocking first render
      unawaited(
        container
            .read(notificationServiceProvider)
            .initialize()
            .catchError((Object _) {}),
      );

      // Pre-warm auth state (from local cache) so destination screen is ready
      try {
        await container.read(authStateProvider.future).timeout(
              const Duration(milliseconds: 300),
              onTimeout: () => null,
            );
      } catch (_) {}

      if (!mounted) {
        container.dispose();
        return;
      }
      setState(() => _container = container);
    } catch (error, stack) {
      if (Firebase.apps.isNotEmpty) {
        unawaited(FirebaseCrashlytics.instance
            .recordError(error, stack, fatal: true));
      }
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _container?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final container = _container;
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(accent: _accent),
        darkTheme: _oledMode
            ? AppTheme.oled(accent: _accent)
            : AppTheme.dark(accent: _accent),
        themeMode: _themeMode,
        home: _StartupError(onRetry: () {
          setState(() => _error = null);
          unawaited(_initialize());
        }),
      );
    }

    return AnimatedSplashScreen(
      ready: container != null,
      themeMode: _themeMode,
      accent: _accent,
      oledMode: _oledMode,
      child: container == null
          ? null
          : UncontrolledProviderScope(
              container: container,
              child: const EstodoApp(),
            ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 42),
              const SizedBox(height: 16),
              const Text('Uygulama başlatılamadı.'),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: onRetry, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      ),
    );
  }
}

class EstodoApp extends ConsumerWidget {
  const EstodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);
    final onboardingSeen = ref.watch(onboardingSeenProvider);
    final oledMode = ref.watch(oledModeProvider);

    return MaterialApp(
      title: 'estodo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accent),
      darkTheme: oledMode
          ? AppTheme.oled(accent: accent)
          : AppTheme.dark(accent: accent),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supported) {
        if (locale?.languageCode == 'tr') return const Locale('tr');
        return const Locale('en');
      },
      home: !onboardingSeen
          ? const OnboardingScreen()
          : authState.when(
              data: (user) =>
                  user == null ? const AuthScreen() : const HomeScreen(),
              error: (error, _) => AuthScreen(initialError: error.toString()),
              loading: () => const _SplashGate(),
            ),
    );
  }
}

class _SplashGate extends StatelessWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const SizedBox.expand(),
    );
  }
}
