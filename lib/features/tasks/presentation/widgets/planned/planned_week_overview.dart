import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/todo_task.dart';
import '../../utils/planned_layout.dart';

/// Structured-style 7-column week overview revealed when pulling the day sheet
/// down (Screenshot 2) or switching to the Week (H / W) mode.
class PlannedWeekOverview extends StatelessWidget {
  const PlannedWeekOverview({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.accent,
    required this.onSelectDay,
    required this.onOpenTask,
    this.compact = false,
  });

  final List<PlannedDay> days;
  final DateTime selectedDate;
  final Color accent;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<TodoTask> onOpenTask;
  final bool compact;

  static const double leftGutter = 28.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final allScheduled = days.expand((d) => d.scheduled).toList();

    // Determine visible hour range (default 08:00..22:00 like Structured).
    var minHour = 8;
    var maxHour = 22;
    for (final entry in allScheduled) {
      final h = entry.startMinuteOfDay ~/ 60;
      if (h < minHour) minHour = h;
      if (h > maxHour) maxHour = h;
    }
    if (maxHour <= minHour) maxHour = minHour + 1;

    final hPad = compact ? 8.0 : 14.0;

    return Column(
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight =
                  math.max(220.0, constraints.maxHeight - 24.0);
              const badgeSize = 36.0;
              final topPad = 14.0 + badgeSize / 2;
              final bottomPad = 18.0 + badgeSize / 2;
              final usableSpan =
                  math.max(120.0, availableHeight - topPad - bottomPad);
              final totalMinutes = math.max(60, (maxHour - minHour) * 60);

              double yForMinute(int minuteOfDay) {
                final clamped =
                    (minuteOfDay - minHour * 60).clamp(0, totalMinutes);
                return topPad + (clamped / totalMinutes) * usableSpan;
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: math.max(constraints.maxHeight, 300.0),
                  child: Stack(
                    children: [
                      // Left hour gutter (08⁰⁰ .. 22⁰⁰)
                      for (var h = minHour; h <= maxHour; h++)
                        Positioned(
                          left: 4,
                          top: yForMinute(h * 60) - 7,
                          width: leftGutter + hPad - 6,
                          child: _HourLabel(hour: h),
                        ),
                      // 7 day columns aligned with PlannedWeekStrip
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          hPad + leftGutter,
                          0,
                          hPad,
                          0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final day in days)
                              Expanded(
                                child: _WeekDayColumn(
                                  day: day,
                                  selected: PlannedLayout.isSameDay(
                                    day.date,
                                    selectedDate,
                                  ),
                                  badgeSize: badgeSize,
                                  yForMinute: yForMinute,
                                  onSelectDay: () {
                                    HapticFeedback.selectionClick();
                                    onSelectDay(day.date);
                                  },
                                  onOpenTask: (task) {
                                    HapticFeedback.selectionClick();
                                    onSelectDay(day.date);
                                    onOpenTask(task);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (allScheduled.isEmpty &&
                          days.every((d) => d.unscheduled.isEmpty))
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.plannedEmptyWeek,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HourLabel extends StatelessWidget {
  const _HourLabel({required this.hour});

  final int hour;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.65);
    final hh = hour.toString().padLeft(2, '0');
    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
        children: [
          TextSpan(text: hh),
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Transform.translate(
              offset: const Offset(0.5, -2.0),
              child: Text(
                '00',
                style: TextStyle(
                  color: color,
                  fontSize: 6.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({
    required this.day,
    required this.selected,
    required this.badgeSize,
    required this.yForMinute,
    required this.onSelectDay,
    required this.onOpenTask,
  });

  final PlannedDay day;
  final bool selected;
  final double badgeSize;
  final double Function(int minuteOfDay) yForMinute;
  final VoidCallback onSelectDay;
  final ValueChanged<TodoTask> onOpenTask;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = day.scheduled;

    if (entries.isEmpty) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelectDay,
        child: const SizedBox.expand(),
      );
    }

    // Compute non-overlapping Y centers for the badges in this column.
    final centers = <double>[];
    for (final entry in entries) {
      var y = yForMinute(entry.startMinuteOfDay);
      if (centers.isNotEmpty && y - centers.last < badgeSize * 0.78) {
        y = centers.last + badgeSize * 0.78;
      }
      centers.add(y);
    }

    final firstY = centers.first;
    final lastY = centers.length > 1
        ? centers.last
        : math.max(firstY + 48.0, yForMinute(22 * 60));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelectDay,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          final circleSize = math.min(badgeSize, constraints.maxWidth - 4);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Vertical connector line (Structured style)
              Positioned(
                left: centerX - 1.1,
                top: firstY,
                height: math.max(0, lastY - firstY),
                width: 2.2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant
                        .withValues(alpha: selected ? 0.85 : 0.55),
                    borderRadius: BorderRadius.circular(1.1),
                  ),
                ),
              ),
              for (var i = 0; i < entries.length; i++)
                Positioned(
                  left: centerX - circleSize / 2,
                  top: centers[i] - circleSize / 2,
                  width: circleSize,
                  height: circleSize,
                  child: _WeekEntryBadge(
                    entry: entries[i],
                    isDark: isDark,
                    onTap: () => onOpenTask(entries[i].task),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _WeekEntryBadge extends StatelessWidget {
  const _WeekEntryBadge({
    required this.entry,
    required this.isDark,
    required this.onTap,
  });

  final PlannedEntry entry;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isDark
        ? Color.alphaBlend(
            entry.color.withValues(alpha: 0.24),
            const Color(0xFF2C2C2E),
          )
        : Color.alphaBlend(
            entry.color.withValues(alpha: 0.18),
            scheme.surfaceContainerHigh,
          );
    final iconColor =
        isDark ? Color.lerp(entry.color, Colors.white, 0.25)! : entry.color;

    return Tooltip(
      message: entry.task.title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: entry.color.withValues(alpha: 0.32),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            entry.isCompleted ? Icons.check_rounded : entry.icon,
            size: 18,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
