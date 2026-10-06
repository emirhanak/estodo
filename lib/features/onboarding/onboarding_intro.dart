import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// First-launch intro: the screen starts empty, then sample plan blocks and
/// to-dos pop in one by one with a light haptic tick, followed by the
/// headline and the continue button.
class OnboardingIntro extends StatefulWidget {
  const OnboardingIntro({
    super.key,
    required this.onContinue,
    required this.onSignIn,
  });

  final VoidCallback onContinue;
  final VoidCallback onSignIn;

  @override
  State<OnboardingIntro> createState() => _OnboardingIntroState();
}

class _OnboardingIntroState extends State<OnboardingIntro> {
  static const _firstDelay = Duration(milliseconds: 350);
  static const _step = Duration(milliseconds: 230);

  int _shown = 0;
  bool _showFooter = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _shown > 0) return;
    if (MediaQuery.of(context).disableAnimations) {
      _shown = _items.length;
      _showFooter = true;
      return;
    }
    _timer = Timer(_firstDelay, _revealNext);
  }

  void _revealNext() {
    if (!mounted) return;
    if (_shown < _items.length) {
      HapticFeedback.lightImpact();
      setState(() => _shown++);
      _timer = Timer(_step, _revealNext);
    } else {
      setState(() => _showFooter = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      _placed(_items[i], i < _shown, constraints, isTr),
                    Align(
                      alignment: const Alignment(0, 0.02),
                      child: AnimatedOpacity(
                        opacity: _showFooter ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            isTr
                                ? 'Günün sınırlı.\nPlanın net olsun.'
                                : 'Your day is finite.\nMake the plan clear.',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _showFooter ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: IgnorePointer(
                ignoring: !_showFooter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: Column(
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: const StadiumBorder(),
                          textStyle: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: widget.onContinue,
                        child: Text(isTr ? 'Devam et' : 'Continue'),
                      ),
                      TextButton(
                        onPressed: widget.onSignIn,
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
        ),
      ),
    );
  }

  Widget _placed(
    _IntroItem item,
    bool visible,
    BoxConstraints box,
    bool isTr,
  ) {
    final width = box.maxWidth * item.width;
    final left = item.alignRight
        ? box.maxWidth * (1 - item.x) - width
        : box.maxWidth * item.x;
    return Positioned(
      left: left,
      top: box.maxHeight * item.y,
      width: width,
      child: _PopIn(
        visible: visible,
        child: item.isEvent
            ? _EventBlock(item: item, isTr: isTr)
            : _TodoPill(label: isTr ? item.tr : item.en),
      ),
    );
  }
}

/// Scales and fades a card in with a little overshoot.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: visible ? 1 : 0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({required this.item, required this.isTr});

  final _IntroItem item;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final solid = item.solid;
    final background = solid
        ? item.color
        : Color.alphaBlend(item.color.withValues(alpha: 0.22), scheme.surface);
    final foreground = solid ? Colors.white : scheme.onSurface;

    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          if (!solid)
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:
                  solid ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Text(
                  isTr ? item.tr : item.en,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                if (item.time != null && !solid)
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.time!,
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoPill extends StatelessWidget {
  const _TodoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radio_button_unchecked_rounded,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroItem {
  const _IntroItem.event({
    required this.tr,
    required this.en,
    required this.color,
    required this.x,
    required this.y,
    this.time,
    this.solid = false,
    this.alignRight = false,
  })  : isEvent = true,
        width = 0.46;

  const _IntroItem.todo({
    required this.tr,
    required this.en,
    required this.x,
    required this.y,
    this.alignRight = false,
    this.width = 0.6,
  })  : isEvent = false,
        color = Colors.transparent,
        time = null,
        solid = false;

  final bool isEvent;
  final String tr;
  final String en;
  final Color color;
  final String? time;
  final bool solid;

  /// Horizontal inset as a fraction of the width, from the left edge or,
  /// when [alignRight], from the right edge.
  final double x;
  final double y;
  final bool alignRight;
  final double width;
}

// Reveal order is the list order; positions are fractions of the area.
const _items = <_IntroItem>[
  _IntroItem.event(
    tr: 'Sabah koşusu',
    en: 'Morning run',
    time: '07:00 – 07:45',
    color: Color(0xFF8E44AD),
    x: 0.03,
    y: 0.20,
  ),
  _IntroItem.event(
    tr: 'Proje toplantısı',
    en: 'Project sync',
    time: '10:30 – 11:15',
    color: Color(0xFFE6B800),
    x: 0.03,
    y: 0.02,
    alignRight: true,
  ),
  _IntroItem.todo(tr: 'Çöpü çıkar', en: 'Take out trash', x: 0.12, y: 0.13),
  _IntroItem.todo(
    tr: 'Faturayı öde',
    en: 'Pay the bill',
    x: 0.03,
    y: 0.25,
    alignRight: true,
    width: 0.42,
  ),
  _IntroItem.todo(tr: 'Kitap oku', en: 'Read a book', x: 0.14, y: 0.33),
  _IntroItem.event(
    tr: 'Öğle yemeği',
    en: 'Team lunch',
    color: Color(0xFF2ECC71),
    solid: true,
    x: 0.0,
    y: 0.60,
    alignRight: true,
  ),
  _IntroItem.event(
    tr: 'Tasarım incelemesi',
    en: 'Design review',
    time: '14:30 – 15:15',
    color: Color(0xFFE74C3C),
    x: 0.03,
    y: 0.64,
  ),
  _IntroItem.todo(
    tr: 'Masayı topla',
    en: 'Tidy the desk',
    x: 0.06,
    y: 0.78,
    alignRight: true,
  ),
  _IntroItem.event(
    tr: 'Akşam yemeği',
    en: 'Dinner with Ece',
    color: Color(0xFFF1948A),
    solid: true,
    x: 0.03,
    y: 0.88,
  ),
  _IntroItem.event(
    tr: 'Yoga',
    en: 'Yoga',
    time: '19:00 – 20:00',
    color: Color(0xFF1ABC9C),
    x: 0.0,
    y: 0.88,
    alignRight: true,
  ),
];
