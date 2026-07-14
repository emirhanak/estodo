import 'dart:math';

import 'package:flutter/material.dart';

void showConfettiBurst(
  BuildContext context, {
  required Offset position,
  required Color accent,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ConfettiOverlay(
      position: position,
      accent: accent,
      onDone: entry.remove,
    ),
  );
  overlay.insert(entry);
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({
    required this.position,
    required this.accent,
    required this.onDone,
  });

  final Offset position;
  final Color accent;
  final VoidCallback onDone;

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _Particle.generate(widget.accent, count: 20);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _ctrl.value,
            origin: widget.position,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.width,
    required this.height,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });

  final double angle;
  final double speed;
  final double width;
  final double height;
  final Color color;
  final double rotation;
  final double rotationSpeed;

  static List<_Particle> generate(Color accent, {required int count}) {
    final rng = Random();
    final palette = <Color>[
      accent,
      Colors.amber.shade400,
      Colors.pinkAccent.shade100,
      Colors.lightBlueAccent.shade100,
      Colors.white,
      Colors.greenAccent.shade400,
      accent.withValues(alpha: 0.7),
    ];
    return List.generate(count, (_) {
      // bias toward upward burst: angle between -160° and -20° (in radians)
      final baseAngle = -pi / 2;
      final spread = pi * 0.9;
      return _Particle(
        angle: baseAngle + (rng.nextDouble() - 0.5) * spread,
        speed: 100 + rng.nextDouble() * 180,
        width: 6 + rng.nextDouble() * 6,
        height: 3 + rng.nextDouble() * 4,
        color: palette[rng.nextInt(palette.length)],
        rotation: rng.nextDouble() * 2 * pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 14,
      );
    });
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.origin,
  });

  final List<_Particle> particles;
  final double progress;
  final Offset origin;

  static const double _gravity = 320;

  @override
  void paint(Canvas canvas, Size size) {
    // fade out in last 30%
    final opacity =
        progress > 0.7 ? ((1 - progress) / 0.3).clamp(0.0, 1.0) : 1.0;
    final t = progress;

    for (final p in particles) {
      final dx = cos(p.angle) * p.speed * t;
      final dy = sin(p.angle) * p.speed * t + 0.5 * _gravity * t * t;
      final x = origin.dx + dx;
      final y = origin.dy + dy;
      final rot = p.rotation + p.rotationSpeed * t;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.color.a * opacity);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.width,
          height: p.height,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
