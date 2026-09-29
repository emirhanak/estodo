import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Keeps the native launch screen from handing off to a blank frame while the
/// app services are initialized, then reveals the destination app with a fluid,
/// theme-aware animated transition.
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({
    super.key,
    required this.ready,
    this.child,
    this.themeMode,
    this.accent,
    this.oledMode = false,
  });

  final bool ready;
  final Widget? child;
  final ThemeMode? themeMode;
  final Color? accent;
  final bool oledMode;

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  /// Snappy branded presentation without artificial sluggishness.
  static const _minimumDuration = Duration(milliseconds: 450);

  /// Smooth, cinematic exit reveal duration.
  static const _exitDuration = Duration(milliseconds: 380);

  late final AnimationController _introController;
  late final AnimationController _exitController;
  late final Animation<double> _exitCurve;
  late final Animation<double> _appScale;
  late final Animation<double> _appFade;

  bool _splashDone = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: _minimumDuration,
    )..forward();

    _exitController = AnimationController(
      vsync: this,
      duration: _exitDuration,
    );

    _exitCurve = CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInOutCubic,
    );

    _appScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeOutCubic,
      ),
    );

    _appFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
      ),
    );

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _checkReadyAndExit();
    });

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _splashDone = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _introController.value = 1.0;
      _checkReadyAndExit();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && !oldWidget.ready) {
      _checkReadyAndExit();
    }
  }

  void _checkReadyAndExit() {
    if (!widget.ready || _splashDone || _exitController.isAnimating || _exitController.isCompleted) {
      return;
    }
    if (!_reduceMotion && !_introController.isCompleted) {
      return;
    }

    if (_reduceMotion) {
      _exitController.value = 1.0;
      if (mounted) setState(() => _splashDone = true);
    } else {
      _exitController.forward();
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light(accent: widget.accent);
    final darkTheme = widget.oledMode
        ? AppTheme.oled(accent: widget.accent)
        : AppTheme.dark(accent: widget.accent);
    final mode = widget.themeMode ?? ThemeMode.system;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: mode,
      home: Builder(
        builder: (context) {
          final isExiting = _exitController.isAnimating || _exitController.isCompleted;

          if (_splashDone && widget.child != null) {
            return widget.child!;
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Destination app reveals underneath during exit transition
              if (widget.child != null && isExiting)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _exitController,
                    builder: (context, child) => FadeTransition(
                      opacity: _appFade,
                      child: Transform.scale(
                        scale: _appScale.value,
                        child: child,
                      ),
                    ),
                    child: widget.child!,
                  ),
                ),

              // Splash screen overlay
              if (!_splashDone)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _exitCurve,
                    builder: (context, splashChild) {
                      final fadeOut = (1.0 - _exitCurve.value).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: fadeOut,
                        child: splashChild,
                      );
                    },
                    child: _SplashVisual(
                      intro: _introController,
                      exit: _exitController,
                      reduceMotion: _reduceMotion,
                    ),
                  ),
                ),
            ],
          );
        },
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
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([intro, exit]),
          builder: (context, _) {
            final introProgress = reduceMotion
                ? 1.0
                : Curves.easeOutCubic.transform(
                    const Interval(0.0, 0.85, curve: Curves.easeOutCubic)
                        .transform(intro.value),
                  );

            final exitProgress = reduceMotion
                ? 1.0
                : Curves.fastOutSlowIn.transform(exit.value);

            final logoOpacity = (introProgress * (1.0 - exitProgress)).clamp(0.0, 1.0);
            final logoScale = 0.88 + (introProgress * 0.12) + (exitProgress * 0.14);

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
