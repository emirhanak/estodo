import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'onboarding_cards.dart';

/// Last intro step: invites the user to plan today, with a small animated
/// sketch of a week strip and a timeline being filled in.
class OnboardingStartPage extends StatefulWidget {
  const OnboardingStartPage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<OnboardingStartPage> createState() => _OnboardingStartPageState();
}

class _OnboardingStartPageState extends State<OnboardingStartPage> {
  static const _parts = 11; // 7 week dots + 4 timeline pieces

  int _shown = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _shown > 0) return;
    if (MediaQuery.of(context).disableAnimations) {
      _shown = _parts;
      return;
    }
    _timer = Timer(const Duration(milliseconds: 300), _tick);
  }

  void _tick() {
    if (!mounted || _shown >= _parts) return;
    if (_shown >= 7) HapticFeedback.lightImpact();
    setState(() => _shown++);
    _timer = Timer(Duration(milliseconds: _shown < 7 ? 110 : 380), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: isTr ? 'Bugünü' : 'Today',
                  style: TextStyle(color: scheme.primary),
                ),
                TextSpan(
                  text: isTr
                      ? ' planlayarak başlayalım…'
                      : ' is a good place to start…',
                ),
              ],
            ),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isTr
                ? 'Görevini ekle, saat ver, gününü gör.'
                : 'Add a task, give it a time, see your day.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(child: _Sketch(shown: _shown)),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: widget.onStart,
            child: Text(isTr ? 'Planlamaya başla' : 'Start planning'),
          ),
        ],
      ),
    );
  }
}

class _Sketch extends StatelessWidget {
  const _Sketch({required this.shown});

  final int shown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final pale = accent.withValues(alpha: 0.25);
    const blue = Color(0xFF5B8DEF);

    Widget capsule(IconData icon, {double height = 72}) => Container(
          width: 52,
          height: height,
          decoration: BoxDecoration(
            color: blue.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Icon(icon, color: Colors.white),
        );

    Widget bar(double width) => Container(
          width: width,
          height: 12,
          decoration: BoxDecoration(
            color: blue.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 7; i++)
              PopIn(
                visible: shown > i,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: pale,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        PopIn(
          visible: shown > 7,
          child: Row(
            children: [
              capsule(Icons.shopping_cart_outlined),
              const SizedBox(width: 16),
              bar(90),
              const SizedBox(width: 6),
              bar(48),
              const Spacer(),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PopIn(
          visible: shown > 8,
          child: SizedBox(
            width: 52,
            height: 84,
            child: CustomPaint(
              painter: _DottedCapsulePainter(color: blue),
            ),
          ),
        ),
        const SizedBox(height: 12),
        PopIn(
          visible: shown > 9,
          child: capsule(Icons.school_outlined),
        ),
        const SizedBox(height: 12),
        PopIn(
          visible: shown > 10,
          child: Row(
            children: [
              const SizedBox(width: 68),
              bar(120),
            ],
          ),
        ),
      ],
    );
  }
}

class _DottedCapsulePainter extends CustomPainter {
  _DottedCapsulePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width / 2),
    );
    final path = Path()..addRRect(rrect.deflate(2));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        final pos = metric.getTangentForOffset(d)?.position;
        if (pos != null) canvas.drawCircle(pos, 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DottedCapsulePainter old) => old.color != color;
}
