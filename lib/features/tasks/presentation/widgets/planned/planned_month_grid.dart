import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/task_list.dart';
import '../../../domain/entities/todo_task.dart';
import '../../utils/planned_layout.dart';
import 'planned_format.dart';

class PlannedMonthGrid extends StatelessWidget {
  const PlannedMonthGrid({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.tasks,
    required this.lists,
    required this.accent,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime selectedDate;
  final List<TodoTask> tasks;
  final List<TaskList> lists;
  final Color accent;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final mondayFirst = PlannedFormat.mondayFirst(context);
    final first = DateTime(month.year, month.month);
    final gridStart = PlannedLayout.weekStart(first, mondayFirst: mondayFirst);
    final days = List.generate(42, (i) => gridStart.add(Duration(days: i)));
    final labels = <String>[];
    for (var i = 0; i < 7; i++) {
      labels.add(PlannedFormat.weekdayShort(
          days[i], PlannedFormat.intlLocale(context)));
    }
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
          child: Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 120),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.82,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              final entries = tasks
                  .where((t) => PlannedLayout.belongsToDay(t, date))
                  .toList();
              final dots = PlannedLayout.dayDots(
                date,
                tasks: entries,
                lists: lists,
                fallback: accent,
                max: 3,
              );
              final selected = PlannedLayout.isSameDay(date, selectedDate);
              final today = PlannedLayout.isSameDay(date, DateTime.now());
              final inMonth = date.month == month.month;
              return Semantics(
                button: true,
                selected: selected,
                label:
                    '${date.day}, ${entries.length} ${AppLocalizations.of(context).tasks.toLowerCase()}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelectDay(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.all(2),
                    padding:
                        const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
                    decoration: BoxDecoration(
                      color: selected
                          ? accent
                          : today
                              ? accent.withValues(alpha: 0.10)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: today && !selected
                          ? Border.all(color: accent.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${date.day}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: selected
                                        ? scheme.onPrimary
                                        : inMonth
                                            ? scheme.onSurface
                                            : scheme.onSurfaceVariant
                                                .withValues(alpha: 0.42),
                                    fontWeight: selected || today
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                        ),
                        const Spacer(),
                        if (entries.isNotEmpty)
                          Text(
                            '${entries.length}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: selected
                                      ? scheme.onPrimary
                                      : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final color in dots)
                              Container(
                                width: 5,
                                height: 5,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: selected ? scheme.onPrimary : color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
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
