import 'package:flutter/material.dart';

/// Scales and fades a child in with a little overshoot.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: visible ? 1 : 0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
    );
  }
}

/// A calendar-style block: tinted card with a color bar, or a solid card.
class IntroEventBlock extends StatelessWidget {
  const IntroEventBlock({super.key, required this.card, required this.isTr});

  final IntroCard card;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final solid = card.solid;
    final background = solid
        ? card.color
        : Color.alphaBlend(
            card.color.withValues(alpha: isDark ? 0.32 : 0.22),
            scheme.surface,
          );
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
                color: card.color,
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
                  isTr ? card.tr : card.en,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                if (card.time != null && !solid)
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        card.time!,
                        style: theme.textTheme.labelSmall?.copyWith(
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

/// A to-do pill: empty check circle and a label.
class IntroTodoPill extends StatelessWidget {
  const IntroTodoPill({super.key, required this.label});

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

class IntroCard {
  const IntroCard.event({
    required this.tr,
    required this.en,
    required this.color,
    required this.x,
    required this.y,
    required this.pileX,
    required this.pileY,
    required this.pileAngle,
    this.time,
    this.solid = false,
    this.alignRight = false,
  })  : isEvent = true,
        width = 0.46;

  const IntroCard.todo({
    required this.tr,
    required this.en,
    required this.x,
    required this.y,
    required this.pileX,
    required this.pileY,
    required this.pileAngle,
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

  /// Resting place: horizontal inset as a fraction of the width, from the
  /// left edge or, when [alignRight], from the right edge.
  final double x;
  final double y;
  final bool alignRight;
  final double width;

  /// Where the card lands when the plan "collapses": left edge and top as
  /// fractions of the area, plus its tilt in radians.
  final double pileX;
  final double pileY;
  final double pileAngle;
}

/// Reveal order is the list order.
const introCards = <IntroCard>[
  IntroCard.event(
    tr: 'Sabah koşusu',
    en: 'Morning run',
    time: '07:00 – 07:45',
    color: Color(0xFF8E44AD),
    x: 0.03,
    y: 0.20,
    pileX: 0.18,
    pileY: 0.70,
    pileAngle: -0.35,
  ),
  IntroCard.event(
    tr: 'Proje toplantısı',
    en: 'Project sync',
    time: '10:30 – 11:15',
    color: Color(0xFFE6B800),
    x: 0.03,
    y: 0.02,
    alignRight: true,
    pileX: 0.50,
    pileY: 0.55,
    pileAngle: -1.1,
  ),
  IntroCard.todo(
    tr: 'Çöpü çıkar',
    en: 'Take out trash',
    x: 0.12,
    y: 0.13,
    pileX: 0.30,
    pileY: 0.62,
    pileAngle: 0.12,
  ),
  IntroCard.todo(
    tr: 'Faturayı öde',
    en: 'Pay the bill',
    x: 0.03,
    y: 0.25,
    alignRight: true,
    width: 0.42,
    pileX: 0.62,
    pileY: 0.64,
    pileAngle: -1.0,
  ),
  IntroCard.todo(
    tr: 'Kitap oku',
    en: 'Read a book',
    x: 0.14,
    y: 0.33,
    pileX: 0.26,
    pileY: 0.78,
    pileAngle: -0.4,
  ),
  IntroCard.event(
    tr: 'Öğle yemeği',
    en: 'Team lunch',
    color: Color(0xFF2ECC71),
    solid: true,
    x: 0.0,
    y: 0.60,
    alignRight: true,
    pileX: 0.50,
    pileY: 0.78,
    pileAngle: -0.45,
  ),
  IntroCard.event(
    tr: 'Tasarım incelemesi',
    en: 'Design review',
    time: '14:30 – 15:15',
    color: Color(0xFFE74C3C),
    x: 0.03,
    y: 0.64,
    pileX: 0.02,
    pileY: 0.86,
    pileAngle: 0.15,
  ),
  IntroCard.todo(
    tr: 'Masayı topla',
    en: 'Tidy the desk',
    x: 0.06,
    y: 0.78,
    alignRight: true,
    pileX: 0.40,
    pileY: 0.88,
    pileAngle: -0.3,
  ),
  IntroCard.event(
    tr: 'Akşam yemeği',
    en: 'Dinner with Ece',
    color: Color(0xFFF1948A),
    solid: true,
    x: 0.03,
    y: 0.88,
    pileX: 0.08,
    pileY: 0.95,
    pileAngle: 0.0,
  ),
  IntroCard.event(
    tr: 'Yoga',
    en: 'Yoga',
    time: '19:00 – 20:00',
    color: Color(0xFF1ABC9C),
    x: 0.0,
    y: 0.88,
    alignRight: true,
    pileX: 0.52,
    pileY: 0.93,
    pileAngle: -0.5,
  ),
];
