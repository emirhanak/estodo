import 'package:flutter/material.dart';

import '../../../domain/entities/task_list.dart';
import '../../../domain/entities/todo_task.dart';
import '../../utils/planned_layout.dart';
import 'planned_format.dart';

/// Swipeable Mon–Sun strip with a per-day color preview, mirroring the
/// Structured week header.
class PlannedWeekStrip extends StatefulWidget {
  const PlannedWeekStrip({
    super.key,
    required this.selectedDate,
    required this.tasks,
    required this.lists,
    required this.accent,
    required this.onSelect,
    this.compact = false,
  });

  final DateTime selectedDate;
  final List<TodoTask> tasks;
  final List<TaskList> lists;
  final Color accent;
  final ValueChanged<DateTime> onSelect;
  final bool compact;

  @override
  State<PlannedWeekStrip> createState() => _PlannedWeekStripState();
}

class _PlannedWeekStripState extends State<PlannedWeekStrip> {
  static const _basePage = 2600;

  late DateTime _anchorWeek;
  late final PageController _controller;
  bool _mondayFirst = true;

  @override
  void initState() {
    super.initState();
    _anchorWeek = PlannedLayout.weekStart(
      widget.selectedDate,
      mondayFirst: true,
    );
    _controller = PageController(initialPage: _basePage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mondayFirst = PlannedFormat.mondayFirst(context);
    if (mondayFirst != _mondayFirst) {
      _mondayFirst = mondayFirst;
      _anchorWeek = PlannedLayout.weekStart(
        widget.selectedDate,
        mondayFirst: mondayFirst,
      );
    }
  }

  @override
  void didUpdateWidget(covariant PlannedWeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!PlannedLayout.isSameDay(widget.selectedDate, oldWidget.selectedDate)) {
      _syncPage();
    }
  }

  void _syncPage() {
    if (!_controller.hasClients) return;
    final target = _pageOf(widget.selectedDate);
    final current = _controller.page?.round() ?? _basePage;
    if (target == current) return;
    if ((target - current).abs() > 3) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  int _pageOf(DateTime date) {
    final week = PlannedLayout.weekStart(date, mondayFirst: _mondayFirst);
    return _basePage + (week.difference(_anchorWeek).inDays / 7).round();
  }

  DateTime _weekOfPage(int page) =>
      _anchorWeek.add(Duration(days: (page - _basePage) * 7));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 84.0 : 92.0;
    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: _controller,
        onPageChanged: (page) {
          final week = _weekOfPage(page);
          final weekday = widget.selectedDate.weekday;
          final target = week.add(
            Duration(days: _mondayFirst ? weekday - 1 : weekday % 7),
          );
          if (!PlannedLayout.isSameDay(target, widget.selectedDate)) {
            widget.onSelect(target);
          }
        },
        itemBuilder: (context, page) {
          final days = PlannedLayout.weekDays(_weekOfPage(page));
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 14),
            child: Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: _DayCell(
                      date: day,
                      accent: widget.accent,
                      selected: PlannedLayout.isSameDay(
                        day,
                        widget.selectedDate,
                      ),
                      isToday: PlannedLayout.isSameDay(day, DateTime.now()),
                      dots: PlannedLayout.dayDots(
                        day,
                        tasks: widget.tasks,
                        lists: widget.lists,
                        fallback: widget.accent,
                      ),
                      onTap: () => widget.onSelect(day),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.accent,
    required this.selected,
    required this.isToday,
    required this.dots,
    required this.onTap,
  });

  final DateTime date;
  final Color accent;
  final bool selected;
  final bool isToday;
  final List<Color> dots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = PlannedFormat.intlLocale(context);
    final label = PlannedFormat.weekdayShort(date, locale);
    final numberColor = selected
        ? scheme.onPrimary
        : isToday
            ? accent
            : scheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label ${date.day}',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday ? accent : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              key: ValueKey(selected),
              tween: Tween(begin: selected ? 0.7 : 1, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: numberColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final color in dots)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: selected ? 1 : 0.75),
                          shape: BoxShape.circle,
                        ),
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
