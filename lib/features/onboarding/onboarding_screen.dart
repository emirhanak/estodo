import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/preferences_provider.dart';
import 'onboarding_cards_scene.dart';
import 'onboarding_start_page.dart';
import 'onboarding_timeline_scene.dart';

/// First-launch intro, told in steps like Structured's:
/// 0. sample tasks pop in around "your day is finite";
/// 1. they collapse into a pile – a calendar never warns you;
/// 2. the pile clears – estodo shows how the day fits together;
/// 3. a timeline fills in and gets checked off;
/// 4. "let's start by planning today".
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _lastStep = 4;

  int _step = 0;
  bool _cardsRevealed = false;

  void _finish() => ref.read(onboardingSeenProvider.notifier).markSeen();

  void _next() {
    if (_step == _lastStep) return _finish();
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: switch (_step) {
            _lastStep => OnboardingStartPage(
                key: const ValueKey('start'),
                onStart: _finish,
              ),
            3 => _Framed(
                key: const ValueKey('timeline'),
                buttonLabel: isTr ? 'Hadi başlayalım' : "Let's begin",
                onNext: _next,
                onSignIn: _finish,
                child: const OnboardingTimelineScene(),
              ),
            _ => _Framed(
                key: const ValueKey('cards'),
                buttonLabel: isTr ? 'Devam et' : 'Continue',
                showButton: _cardsRevealed,
                onNext: _next,
                onSignIn: _finish,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: OnboardingCardsScene(
                        phase: CardsPhase.values[_step],
                        onRevealed: () => setState(() => _cardsRevealed = true),
                      ),
                    ),
                    _Headline(step: _step, visible: _cardsRevealed),
                  ],
                ),
              ),
          },
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.step, required this.visible});

  final int step;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final text = switch (step) {
      0 => isTr
          ? 'Günün sınırlı.\nPlanın net olsun.'
          : 'Your day is finite.\nMake the plan clear.',
      1 => isTr
          ? 'Ama takvim, yükün ne zaman\nfazlalaştığını söylemez.'
          : "But a calendar won't tell you\nwhen it's too much.",
      _ => isTr
          ? 'estodo, gününün nasıl\nbir araya geldiğini gösterir.'
          : 'estodo shows how your\nwhole day fits together.',
    };

    return AnimatedAlign(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      alignment: Alignment(0, step == 1 ? -0.25 : 0.02),
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Padding(
            key: ValueKey(step),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scene plus the shared footer: primary button and a sign-in link.
class _Framed extends StatelessWidget {
  const _Framed({
    super.key,
    required this.child,
    required this.buttonLabel,
    required this.onNext,
    required this.onSignIn,
    this.showButton = true,
  });

  final Widget child;
  final String buttonLabel;
  final VoidCallback onNext;
  final VoidCallback onSignIn;
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Expanded(child: child),
        AnimatedOpacity(
          opacity: showButton ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          child: IgnorePointer(
            ignoring: !showButton,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: const StadiumBorder(),
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: onNext,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(buttonLabel, key: ValueKey(buttonLabel)),
                    ),
                  ),
                  TextButton(
                    onPressed: onSignIn,
                    child: Text.rich(
                      TextSpan(
                        text: isTr
                            ? 'Zaten hesabın var mı? '
                            : 'Already have an account? ',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                        children: [
                          TextSpan(
                            text: isTr ? 'Giriş yap' : 'Sign in',
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
