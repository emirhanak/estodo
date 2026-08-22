import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/todo_task.dart';
import '../../utils/planned_layout.dart';
import 'planned_capsule.dart';
import 'planned_format.dart';

/// Seven-column week grid: every task is a capsule placed by start time and
/// sized by duration, the way Structured shows a week at a glance.
class PlannedWeekGrid extends StatelessWidget {
  const PlannedWeekGrid({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.now,
    required this.accent,
    required this.onOpen,
    required this.onAddAt,
    required this.onSelectDay,
    this.pxPerMinute = 1.1,
  });

  final List<PlannedDay> days;
  final DateTime selectedDate;
  final DateTime now;
  final Color accent;
  final void Function(TodoTask task) onOpen;
  final void Function(DateTime start) onAddAt;
  final void Function(DateTime date) onSelectDay;
  final double pxPerMinute;

  static const double _gutter = 46;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final entries = days.expand((day) => day.scheduled).toList();
    final (windowStart, windowEnd) = PlannedLayout.weekWindow(entries);
    final height = (windowEnd - windowStart) * pxPerMinute;

    if (entries.isEmpty && days.every((d) => d.unscheduled.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.plannedEmptyWeek,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = (constraints.maxWidth - _gutter) / days.length;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 140, top: 4),
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: height + 16,
            child: Stack(
              children: [
                _HourGrid(
                  windowStart: windowStart,
                  windowEnd: windowEnd,
                  pxPerMinute: pxPerMinute,
                  gutter: _gutter,
                ),
                for (var i = 0; i < days.length; i++)
                  Positioned(
                    left: _gutter + i * columnWidth,
                    top: 0,
                    width: columnWidth,
                    height: height,
                    child: _DayColumn(
                      day: days[i],
                      width: columnWidth,
                      windowStart: windowStart,
                      pxPerMinute: pxPerMinute,
                      now: now,
                      accent: accent,
                      selected: PlannedLayout.isSameDay(
                        days[i].date,
                        selectedDate,
                      ),
                      onOpen: onOpen,
                      onAddAt: onAddAt,
                      onSelectDay: onSelectDay,
                    ),
                  ),
                if (days.any((d) => PlannedLayout.isSameDay(d.date, now)))
                  Positioned(
                    left: _gutter - 6,
                    right: 0,
                    top: ((now.hour * 60 + now.minute) - windowStart) *
                        pxPerMinute,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1.5,
                            color: accent.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HourGrid extends StatelessWidget {
  const _HourGrid({
    required this.windowStart,
    required this.windowEnd,
    required this.pxPerMinute,
    required this.gutter,
  });

  final int windowStart;
  final int windowEnd;
  final double pxPerMinute;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hours = <Widget>[];
    for (var minute = windowStart; minute <= windowEnd; minute += 60) {
      final top = (minute - windowStart) * pxPerMinute;
      hours.add(
        Positioned(
          left: 0,
          right: 0,
          top: top,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: gutter,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${(minute ~/ 60).toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(children: hours);
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.width,
    required this.windowStart,
    required this.pxPerMinute,
    required this.now,
    required this.accent,
    required this.selected,
    required this.onOpen,
    required this.onAddAt,
    required this.onSelectDay,
  });

  final PlannedDay day;
  final double width;
  final int windowStart;
  final double pxPerMinute;
  final DateTime now;
  final Color accent;
  final bool selected;
  final void Function(TodoTask task) onOpen;
  final void Function(DateTime start) onAddAt;
  final void Function(DateTime date) onSelectDay;

  @override
  Widget build(BuildContext context) {
    final isToday = PlannedLayout.isSameDay(day.date, now);
    final capsuleWidth = (width - 10).clamp(26.0, 78.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        onSelectDay(day.date);
        final minute =
            windowStart + (details.localPosition.dy / pxPerMinute).round();
        final rounded = (minute ~/ 15) * 15;
        onAddAt(
          DateTime(day.date.year, day.date.month, day.date.day)
              .add(Duration(minutes: rounded.clamp(0, 23 * 60 + 45))),
        );
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.07)
                    : isToday
                        ? accent.withValues(alpha: 0.04)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          for (final entry in day.scheduled)
            Positioned(
              left: (width - capsuleWidth) / 2,
              width: capsuleWidth,
              top: (entry.startMinuteOfDay - windowStart) * pxPerMinute,
              height: (entry.durationMinutes * pxPerMinute).clamp(30.0, 600.0),
              child: _GridCapsule(
                entry: entry,
                now: now,
                dimmed: !selected && !isToday,
                onTap: () => onOpen(entry.task),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridCapsule extends StatelessWidget {
  const _GridCapsule({
    required this.entry,
    required this.now,
    required this.dimmed,
    required this.onTap,
  });

  final PlannedEntry entry;
  final DateTime now;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = entry.isActiveAt(now);
    final color = entry.isCompleted
        ? entry.color.withValues(alpha: 0.22)
        : entry.color.withValues(alpha: dimmed ? 0.35 : 1);
    final foreground = entry.isCompleted
        ? entry.color
        : PlannedCapsule.foregroundOn(entry.color);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Tooltip(
        message:
            '${PlannedFormat.time(entry.start ?? now)} · ${entry.task.title}',
        waitDuration: const Duration(milliseconds: 500),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                border:
                    active ? Border.all(color: entry.color, width: 2) : null,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final icon = Icon(
                    entry.isCompleted ? Icons.check_rounded : entry.icon,
                    size: constraints.maxHeight < 30 ? 12 : 16,
                    color: foreground,
                  );
                  if (constraints.maxHeight < 56) {
                    return Center(child: icon);
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        icon,
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              entry.task.title,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                                color: foreground,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
