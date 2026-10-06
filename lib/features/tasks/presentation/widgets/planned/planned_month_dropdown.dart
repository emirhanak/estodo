import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/task_list.dart';
import '../../../domain/entities/todo_task.dart';
import '../../utils/planned_layout.dart';
import 'planned_format.dart';

/// Month calendar that drops down from the planned header, like
/// Structured's: page between months, see colored dots for busy days and
/// tap a day to jump to it.
class PlannedMonthDropdown extends StatefulWidget {
  const PlannedMonthDropdown({
    super.key,
    required this.selectedDate,
    required this.tasks,
    required this.lists,
    required this.accent,
    required this.onSelect,
  });

  final DateTime selectedDate;
  final List<TodoTask> tasks;
  final List<TaskList> lists;
  final Color accent;
  final ValueChanged<DateTime> onSelect;

  @override
  State<PlannedMonthDropdown> createState() => _PlannedMonthDropdownState();
}

class _PlannedMonthDropdownState extends State<PlannedMonthDropdown> {
  late DateTime _month =
      DateTime(widget.selectedDate.year, widget.selectedDate.month);

  void _shift(int months) {
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + months));
  }

  @override
  Widget build(BuildContext context) {
    final locale = PlannedFormat.intlLocale(context);
    final mondayFirst = PlannedFormat.mondayFirst(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final gridStart = PlannedLayout.weekStart(_month, mondayFirst: mondayFirst);
    final nextMonth = DateTime(_month.year, _month.month + 1);
    final weeks = (nextMonth.difference(gridStart).inDays / 7).ceil();
    final days = List.generate(
      weeks * 7,
      (i) => DateTime(gridStart.year, gridStart.month, gridStart.day + i),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: Text(
                  '${PlannedFormat.monthYear(_month, locale)} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _shift(1),
              ),
            ],
          ),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    PlannedFormat.weekdayShort(days[i], locale),
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var w = 0; w < weeks; w++)
            Row(
              children: [
                for (final day in days.skip(w * 7).take(7))
                  Expanded(child: _cell(day)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(DateTime day) {
    final scheme = Theme.of(context).colorScheme;
    final inMonth = day.month == _month.month;
    final selected = PlannedLayout.isSameDay(day, widget.selectedDate);
    final isToday = PlannedLayout.isSameDay(day, DateTime.now());
    final dots = inMonth
        ? PlannedLayout.dayDots(
            day,
            tasks: widget.tasks,
            lists: widget.lists,
            fallback: widget.accent,
          )
        : const <Color>[];
    final numberColor = selected
        ? scheme.onPrimary
        : isToday
            ? widget.accent
            : inMonth
                ? scheme.onSurface
                : scheme.onSurfaceVariant.withValues(alpha: 0.4);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onSelect(day);
      },
      child: SizedBox(
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? widget.accent : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: numberColor,
                      fontWeight: selected || isToday
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final color in dots.take(3))
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
