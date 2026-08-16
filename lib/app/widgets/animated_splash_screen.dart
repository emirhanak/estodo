import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Keeps the native launch screen from handing off to a blank frame while the
/// app services are initialized, then reveals the destination app.
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key, required this.ready, this.child});

  final bool ready;
  final Widget? child;

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  static const _minimumDuration = Duration(milliseconds: 900);
  static const _exitDuration = Duration(milliseconds: 220);

  late final AnimationController _introController;
  late final AnimationController _exitController;
  bool _showApp = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: _minimumDuration,
    )..forward();
    _exitController = AnimationController(vsync: this, duration: _exitDuration);
    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finishWhenReady();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _introController.value = 1;
      _finishWhenReady();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && !oldWidget.ready) _finishWhenReady();
  }

  void _finishWhenReady() {
    if (!widget.ready ||
        _showApp ||
        (!_reduceMotion && !_introController.isCompleted)) {
      return;
    }
    _exitController.forward().whenComplete(() {
      if (mounted) setState(() => _showApp = true);
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: AnimatedSwitcher(
        duration:
            _reduceMotion ? const Duration(milliseconds: 120) : _exitDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: _showApp && widget.child != null
            ? KeyedSubtree(key: const ValueKey('app'), child: widget.child!)
            : KeyedSubtree(
                key: const ValueKey('splash'),
                child: _SplashVisual(
                  intro: _introController,
                  exit: _exitController,
                  reduceMotion: _reduceMotion,
                ),
              ),
      ),
    );
  }
}

class _SplashVisual extends StatelessWidget {
  const _SplashVisual({
    required this.intro,
    required this.exit,
    required this.reduceMotion,
  });

  final Animation<double> intro;
  final Animation<double> exit;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([intro, exit]),
          builder: (context, _) {
            final drawProgress = reduceMotion
                ? 1.0
                : Curves.easeOutCubic.transform(
                    Interval(0.11, 0.72, curve: Curves.easeOutCubic)
                        .transform(intro.value),
                  );
            final haloProgress = reduceMotion
                ? 0.0
                : Interval(0.0, 0.86, curve: Curves.easeOutCubic)
                    .transform(intro.value);
            final exitProgress = reduceMotion ? 1.0 : exit.value;
            final haloScale =
                0.78 + (haloProgress * 0.5) + (exitProgress * 0.18);
            final haloOpacity =
                (0.16 * haloProgress * (1 - exitProgress)).clamp(0.0, 1.0);
            final logoOpacity = (1 - exitProgress).clamp(0.0, 1.0);
            // Continues the native splash icon for the first moments, so the
            // handoff into the wordmark never flashes a blank screen.
            final iconOpacity = (1 -
                    Curves.easeOut.transform(
                      (intro.value / 0.22).clamp(0.0, 1.0),
                    )) *
                logoOpacity;

            return Opacity(
              opacity: logoOpacity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: haloScale,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary.withValues(alpha: haloOpacity),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary
                                .withValues(alpha: haloOpacity * 1.2),
                            blurRadius: 48,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: iconOpacity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/branding/mainapp.png',
                        width: 88,
                        height: 88,
                      ),
                    ),
                  ),
                  _WordmarkReveal(progress: drawProgress),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WordmarkReveal extends StatelessWidget {
  const _WordmarkReveal({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.001) return const SizedBox(width: 240, height: 96);
    return SizedBox(
      width: 240,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          final leadingEdge = (progress - 0.12).clamp(0.0, 1.0);
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [Colors.transparent, Colors.white, Colors.white],
            stops: [leadingEdge, progress, 1],
          ).createShader(bounds);
        },
        child: SvgPicture.asset(
          'assets/branding/estodo_wordmark.svg',
          fit: BoxFit.contain,
          semanticsLabel: 'estodo',
        ),
      ),
    );
  }
}
