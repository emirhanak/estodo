import 'package:flutter/material.dart';

class AnimatedCheckCircle extends StatefulWidget {
  const AnimatedCheckCircle({
    super.key,
    required this.value,
    required this.onChanged,
    this.color,
    this.size = 26,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? color;
  final double size;

  @override
  State<AnimatedCheckCircle> createState() => _AnimatedCheckCircleState();
}

class _AnimatedCheckCircleState extends State<AnimatedCheckCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.value ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant AnimatedCheckCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.color ?? scheme.primary;
    return Semantics(
      checked: widget.value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onChanged(!widget.value),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final scale = 1.0 + 0.12 * (t < 0.5 ? t * 2 : (1 - t) * 2);
              return Transform.scale(
                scale: scale,
                child: CustomPaint(
                  painter: _CheckPainter(
                    progress: t,
                    accent: accent,
                    border: scheme.outline,
                  ),
                  size: Size.square(widget.size),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({
    required this.progress,
    required this.accent,
    required this.border,
  });

  final double progress;
  final Color accent;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius - 0.8, ringPaint);

    if (progress > 0) {
      final fillPaint = Paint()..color = accent;
      canvas.drawCircle(center, (radius - 0.8) * progress, fillPaint);
    }

    if (progress > 0.4) {
      final checkProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      final checkPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.4;
      final p1 = Offset(size.width * 0.27, size.height * 0.52);
      final p2 = Offset(size.width * 0.45, size.height * 0.7);
      final p3 = Offset(size.width * 0.74, size.height * 0.36);
      if (checkProgress < 0.5) {
        final t = checkProgress / 0.5;
        final mid = Offset.lerp(p1, p2, t)!;
        canvas.drawLine(p1, mid, checkPaint);
      } else {
        canvas.drawLine(p1, p2, checkPaint);
        final t = (checkProgress - 0.5) / 0.5;
        final end = Offset.lerp(p2, p3, t)!;
        canvas.drawLine(p2, end, checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.border != border;
  }
}
