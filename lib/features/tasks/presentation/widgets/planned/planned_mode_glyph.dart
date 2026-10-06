import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Calendar-page icon with a letter on the page, used by the planned view
/// switch (G/H/A in Turkish, D/W/M in English).
class PlannedModeGlyph extends StatelessWidget {
  const PlannedModeGlyph({
    super.key,
    required this.letter,
    required this.color,
    this.size = 26,
  });

  final String letter;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _CalendarLetterPainter(
          letter: letter,
          color: color,
          textDirection: Directionality.of(context),
        ),
      ),
    );
  }
}

class _CalendarLetterPainter extends CustomPainter {
  _CalendarLetterPainter({
    required this.letter,
    required this.color,
    required this.textDirection,
  });

  final String letter;
  final Color color;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final stroke = s * 0.08;
    final page = Rect.fromLTWH(
      stroke / 2,
      s * 0.12,
      s - stroke,
      s * 0.88 - stroke / 2,
    );
    final radius = Radius.circular(s * 0.2);
    final pageShape = RRect.fromRectAndRadius(page, radius);

    // Page outline with a filled header band.
    canvas.drawRRect(
      pageShape,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    final headerHeight = page.height * 0.22;
    canvas.save();
    canvas.clipRRect(pageShape);
    canvas.drawRect(
      Rect.fromLTWH(page.left, page.top, page.width, headerHeight),
      Paint()..color = color,
    );
    canvas.restore();

    // Binder rings.
    final ring = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke * 1.1;
    for (final x in [
      page.left + page.width * 0.3,
      page.right - page.width * 0.3,
    ]) {
      canvas.drawLine(
        Offset(x, stroke / 2),
        Offset(x, page.top + headerHeight * 0.45),
        ring,
      );
    }

    // The letter fills the page body.
    final body = Rect.fromLTRB(
      page.left + stroke,
      page.top + headerHeight,
      page.right - stroke,
      page.bottom - stroke,
    );
    final text = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: color,
          fontSize: body.height * 0.95,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    final scale = math.min(1.0, body.width / text.width);
    canvas.save();
    canvas.translate(body.center.dx, body.center.dy + body.height * 0.03);
    canvas.scale(scale);
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CalendarLetterPainter old) =>
      old.letter != letter ||
      old.color != color ||
      old.textDirection != textDirection;
}
