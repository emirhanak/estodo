import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/preferences_provider.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/auth_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/presentation/providers/theme_mode_provider.dart';
import '../features/tasks/presentation/screens/home_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme/app_theme.dart';

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
