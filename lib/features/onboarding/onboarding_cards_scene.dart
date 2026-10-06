import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'onboarding_cards.dart';

/// What the scattered sample cards are doing.
enum CardsPhase {
  /// Cards pop in one by one around the headline.
  scatter,

  /// Cards tumble down and pile up at the bottom.
  fall,

  /// The pile drops off screen.
  gone,
}

/// Intro scene: sample plan blocks and to-dos appear one by one with a light
/// haptic tick, later tumble into a pile and finally drop away.
class OnboardingCardsScene extends StatefulWidget {
  const OnboardingCardsScene({
    super.key,
    required this.phase,
    required this.onRevealed,
  });

  final CardsPhase phase;

  /// Called once every card is visible.
  final VoidCallback onRevealed;

  @override
  State<OnboardingCardsScene> createState() => _OnboardingCardsSceneState();
}

class _OnboardingCardsSceneState extends State<OnboardingCardsScene>
    with TickerProviderStateMixin {
  static const _firstDelay = Duration(milliseconds: 500);
  static const _step = Duration(milliseconds: 480);

  late final AnimationController _fall = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..addListener(_landingTicks);
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  final _landed = <int>{};
  int _shown = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _shown > 0) return;
    if (MediaQuery.of(context).disableAnimations) {
      _shown = introCards.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onRevealed());
      return;
    }
    _timer = Timer(_firstDelay, _revealNext);
  }

  @override
  void didUpdateWidget(OnboardingCardsScene old) {
    super.didUpdateWidget(old);
    if (old.phase == widget.phase) return;
    _timer?.cancel();
    _shown = introCards.length;
    switch (widget.phase) {
      case CardsPhase.scatter:
        break;
      case CardsPhase.fall:
        _fall.forward(from: 0);
      case CardsPhase.gone:
        _fall.value = 1;
        _exit.forward(from: 0);
    }
  }

  void _revealNext() {
    if (!mounted) return;
    if (_shown < introCards.length) {
      HapticFeedback.lightImpact();
      setState(() => _shown++);
      _timer = Timer(_step, _revealNext);
    } else {
      widget.onRevealed();
    }
  }

  /// One soft tick as each card lands on the pile.
  void _landingTicks() {
    for (var i = 0; i < introCards.length; i++) {
      if (_landed.contains(i) || _fallProgress(i) < 0.98) continue;
      _landed.add(i);
      HapticFeedback.lightImpact();
    }
  }

  double _fallProgress(int i) {
    final start = (i * 0.045).clamp(0.0, 0.5);
    return ((_fall.value - start) / 0.5).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fall.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: Listenable.merge([_fall, _exit]),
        builder: (context, _) => Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < introCards.length; i++) _card(i, box, isTr),
          ],
        ),
      ),
    );
  }

  Widget _card(int i, BoxConstraints box, bool isTr) {
    final card = introCards[i];
    final width = box.maxWidth * card.width;
    final homeLeft = card.alignRight
        ? box.maxWidth * (1 - card.x) - width
        : box.maxWidth * card.x;
    final homeTop = box.maxHeight * card.y;

    final t = _fallProgress(i);
    final drop = Curves.bounceOut.transform(t);
    final turn = Curves.easeOutCubic.transform(t);
    final left = lerpDouble(homeLeft, box.maxWidth * card.pileX, drop)!;
    final exit = Curves.easeInCubic.transform(_exit.value);
    final top = lerpDouble(homeTop, box.maxHeight * card.pileY, drop)! +
        exit * box.maxHeight * 0.7;

    return Positioned(
      left: left,
      top: top,
      width: width,
      child: Opacity(
        opacity: 1 - exit,
        child: Transform.rotate(
          angle: card.pileAngle * turn,
          child: PopIn(
            visible: i < _shown,
            child: card.isEvent
                ? IntroEventBlock(card: card, isTr: isTr)
                : IntroTodoPill(label: isTr ? card.tr : card.en),
          ),
        ),
      ),
    );
  }
}
