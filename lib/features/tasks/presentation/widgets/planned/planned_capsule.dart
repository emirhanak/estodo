import 'package:flutter/material.dart';

import '../../utils/planned_layout.dart';

/// The rounded, duration-sized icon capsule that carries the timeline.
class PlannedCapsule extends StatelessWidget {
  const PlannedCapsule({
    super.key,
    required this.entry,
    required this.height,
    this.width = columnWidth,
    this.progress,
    this.iconSize = 20,
  });

  /// Width the day timeline reserves for the capsule column.
  static const double columnWidth = 44;

  final PlannedEntry entry;
  final double height;
  final double width;

  /// Elapsed fraction for an in-progress task, or null when not running.
  final double? progress;
  final double iconSize;

  static Color foregroundOn(Color color) =>
      color.computeLuminance() > 0.6 ? const Color(0xFF1F1F1F) : Colors.white;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(width / 2);
    final completed = entry.isCompleted;
    final base = completed ? entry.color.withValues(alpha: 0.18) : entry.color;
    final foreground = completed ? entry.color : foregroundOn(entry.color);
    final active = progress != null;

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: active ? entry.color.withValues(alpha: 0.28) : base,
          borderRadius: radius,
          boxShadow: completed || active
              ? null
              : [
                  BoxShadow(
                    color: entry.color.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (active)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress!.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Align(
                    alignment: Alignment.topCenter,
                    child: FractionallySizedBox(
                      heightFactor: value <= 0 ? 0.001 : value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: entry.color),
                      ),
                    ),
                  ),
                ),
              Center(
                child: Icon(
                  completed ? Icons.check_rounded : entry.icon,
                  size: iconSize,
                  color: active ? foregroundOn(entry.color) : foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
