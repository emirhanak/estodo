import 'package:flutter/material.dart';

import '../../../domain/entities/task_list.dart';
import '../../../domain/entities/todo_task.dart';
import '../../utils/planned_layout.dart';
import 'planned_capsule.dart';
import 'planned_format.dart';

/// Swipeable Mon–Sun strip with Structured-style circular colored task/habit
/// icons beneath each day number.
class PlannedWeekStrip extends StatefulWidget {
  const PlannedWeekStrip({
    super.key,
    required this.selectedDate,
    required this.tasks,
    required this.lists,
    required this.accent,
    required this.onSelect,
    this.compact = false,
    this.iconRowOpacity = 1.0,
    this.leftGutter = 0.0,
  });

  final DateTime selectedDate;
  final List<TodoTask> tasks;
  final List<TaskList> lists;
  final Color accent;
  final ValueChanged<DateTime> onSelect;
  final bool compact;

  /// Fades out the mini icon row as the sheet is pulled down into the full
  /// 7-column week overview.
  final double iconRowOpacity;

  /// Optional left offset so the 7 columns line up with the week overview's
  /// hour gutter when pulled down.
  final double leftGutter;

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
    final baseHeight = widget.compact ? 84.0 : 90.0;
    final extraCollapse = (1.0 - widget.iconRowOpacity) * 18.0;
    final height = baseHeight - extraCollapse;

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
          final hPad = widget.compact ? 8.0 : 14.0;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              hPad + widget.leftGutter,
              0,
              hPad,
              0,
            ),
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
                      entries: PlannedLayout.dayPreviewEntries(
                        day,
                        tasks: widget.tasks,
                        lists: widget.lists,
                        fallback: widget.accent,
                        max: 3,
                      ),
                      iconRowOpacity: widget.iconRowOpacity,
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
    required this.entries,
    required this.iconRowOpacity,
    required this.onTap,
  });

  final DateTime date;
  final Color accent;
  final bool selected;
  final bool isToday;
  final List<PlannedEntry> entries;
  final double iconRowOpacity;
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
              tween: Tween(begin: selected ? 0.78 : 1, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
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
            if (iconRowOpacity > 0.02) ...[
              SizedBox(height: 4 * iconRowOpacity),
              Opacity(
                opacity: iconRowOpacity.clamp(0.0, 1.0),
                child: SizedBox(
                  height: 16 * iconRowOpacity,
                  child: entries.isEmpty
                      ? const SizedBox.shrink()
                      : _MiniIconCluster(entries: entries),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders overlapping circular colored badges with the habit/task icon inside,
/// matching Structured's week strip indicators (Screenshot 3).
class _MiniIconCluster extends StatelessWidget {
  const _MiniIconCluster({required this.entries});

  final List<PlannedEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 15.0;
    const overlap = 4.0;
    final count = entries.length;
    final totalWidth = count * size - (count - 1) * overlap;

    return Center(
      child: SizedBox(
        width: totalWidth,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < count; i++)
              Positioned(
                left: i * (size - overlap),
                top: 0,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: entries[i].color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.surface,
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    entries[i].icon,
                    size: 8.5,
                    color: PlannedCapsule.foregroundOn(entries[i].color),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
