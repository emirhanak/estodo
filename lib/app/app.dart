import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  ProviderContainer? _container;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await Bootstrap.initialize();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      final container = ProviderContainer();
      await container.read(notificationServiceProvider).initialize();
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
        home: _StartupError(onRetry: () {
          setState(() => _error = null);
          unawaited(_initialize());
        }),
      );
    }

    return AnimatedSplashScreen(
      ready: container != null,
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

    return MaterialApp(
      title: 'estodo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accent),
      darkTheme: AppTheme.dark(accent: accent),
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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
