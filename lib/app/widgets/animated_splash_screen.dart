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
  static const _minimumDuration = Duration(milliseconds: 1350);
  static const _exitDuration = Duration(milliseconds: 680);

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
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([intro, exit]),
          builder: (context, _) {
            final introProgress = reduceMotion
                ? 1.0
                : Curves.easeOutCubic.transform(
                    Interval(0.08, 0.82).transform(intro.value),
                  );
            final exitProgress = reduceMotion
                ? 1.0
                : Curves.easeInOutCubic.transform(exit.value);
            final logoOpacity =
                (introProgress * (1 - exitProgress)).clamp(0.0, 1.0);
            final logoScale =
                0.84 + (introProgress * 0.16) + (exitProgress * 0.1);

            return Opacity(
              opacity: logoOpacity,
              child: Transform.scale(
                scale: logoScale,
                child: SvgPicture.asset(
                  'lib/app/icon/estodo.svg',
                  width: 230,
                  height: 92,
                  fit: BoxFit.contain,
                  semanticsLabel: 'estodo',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
