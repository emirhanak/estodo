import 'package:flutter/widgets.dart';

import '../../domain/entities/task_list.dart';
import '../../domain/entities/todo_task.dart';
import 'task_icon.dart';

/// One task prepared for the planned timeline: resolved color, icon and the
/// time geometry the timeline needs.
@immutable
class PlannedEntry {
  const PlannedEntry({
    required this.task,
    required this.color,
    required this.icon,
    this.listName,
  });

  final TodoTask task;
  final Color color;
  final IconData icon;
  final String? listName;

  DateTime? get start => task.startAt;

  int get durationMinutes =>
      task.durationMinutes ?? PlannedLayout.defaultDurationMinutes;

  DateTime? get end => start?.add(Duration(minutes: durationMinutes));

  bool get isScheduled => task.startAt != null;

  bool get isCompleted => task.isCompleted;

  int get startMinuteOfDay =>
      start == null ? 0 : start!.hour * 60 + start!.minute;

  int get endMinuteOfDay => startMinuteOfDay + durationMinutes;

  bool isActiveAt(DateTime now) {
    final from = start;
    final to = end;
    if (from == null || to == null || isCompleted) return false;
    return !now.isBefore(from) && now.isBefore(to);
  }

  bool isPastAt(DateTime now) {
    final to = end;
    return to != null && now.isAfter(to);
  }

  /// 0..1 elapsed fraction, used for the in-progress capsule fill.
  double progressAt(DateTime now) {
    final from = start;
    if (from == null || durationMinutes <= 0) return 0;
    final elapsed = now.difference(from).inSeconds;
    final total = durationMinutes * 60;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  int remainingMinutesAt(DateTime now) {
    final to = end;
    if (to == null) return 0;
    final minutes = to.difference(now).inMinutes;
    return minutes < 1 ? 1 : minutes;
  }
}

/// A free window between two scheduled entries.
@immutable
class PlannedGap {
  const PlannedGap({required this.start, required this.minutes});

  final DateTime start;
  final int minutes;
}

/// Everything the planned tab renders for a single calendar day.
@immutable
class PlannedDay {
  const PlannedDay({
    required this.date,
    required this.scheduled,
    required this.unscheduled,
    required this.completed,
  });

  final DateTime date;

  /// Timed tasks (completed ones included) ordered by start time.
  final List<PlannedEntry> scheduled;

  /// Tasks due this day without a start time.
  final List<PlannedEntry> unscheduled;

  /// Completed tasks without a start time.
  final List<PlannedEntry> completed;

  bool get isEmpty =>
      scheduled.isEmpty && unscheduled.isEmpty && completed.isEmpty;

  int get openCount =>
      scheduled.where((e) => !e.isCompleted).length + unscheduled.length;

  int get doneCount =>
      scheduled.where((e) => e.isCompleted).length + completed.length;

  int get totalCount => openCount + doneCount;

  double get progress => totalCount == 0 ? 0 : doneCount / totalCount;

  int get plannedMinutes => scheduled
      .where((e) => !e.isCompleted)
      .fold(0, (sum, e) => sum + e.durationMinutes);
}

/// Pure layout maths for the planned tab. Kept free of widgets so it can be
/// unit tested.
class PlannedLayout {
  const PlannedLayout._();

  static const defaultDurationMinutes = 30;
  static const minGapMinutes = 15;
  static const dayStartMinute = 7 * 60;
  static const dayEndMinute = 22 * 60;

  static DateTime dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime weekStart(DateTime date, {required bool mondayFirst}) {
    final offset = mondayFirst ? date.weekday - 1 : date.weekday % 7;
    return dayOf(date).subtract(Duration(days: offset));
  }

  static List<DateTime> weekDays(DateTime start) =>
      List<DateTime>.generate(7, (i) => start.add(Duration(days: i)));

  /// Stable page index for a day, so PageViews can be virtually infinite.
  static int pageIndexOf(DateTime date) =>
      dayOf(date).difference(_epoch).inDays;

  static DateTime dateOfPage(int index) => _epoch.add(Duration(days: index));

  static final DateTime _epoch = DateTime(2000);

  static Color colorFor(
    TodoTask task,
    Map<String, int> listColors,
    Color fallback,
  ) {
    final listId = task.listId;
    if (listId == null) return fallback;
    final value = listColors[listId];
    return value == null ? fallback : Color(value);
  }

  static PlannedEntry entryOf(
    TodoTask task, {
    required Map<String, int> listColors,
    required Map<String, String> listNames,
    required Color fallback,
  }) {
    return PlannedEntry(
      task: task,
      color: colorFor(task, listColors, fallback),
      icon: TaskIcons.forTask(task),
      listName: task.listId == null ? null : listNames[task.listId],
    );
  }

  /// Tasks belonging to [date] — a task counts for the day of its due date.
  static bool belongsToDay(TodoTask task, DateTime date) {
    final due = task.dueAt;
    if (due == null) return false;
    return isSameDay(due, date);
  }

  static PlannedDay buildDay({
    required DateTime date,
    required List<TodoTask> tasks,
    required List<TaskList> lists,
    required Color fallback,
  }) {
    final listColors = <String, int>{
      for (final list in lists) list.id: list.color,
    };
    final listNames = <String, String>{
      for (final list in lists) list.id: list.name,
    };

    final scheduled = <PlannedEntry>[];
    final unscheduled = <PlannedEntry>[];
    final completed = <PlannedEntry>[];

    for (final task in tasks) {
      if (!belongsToDay(task, date)) continue;
      final entry = entryOf(
        task,
        listColors: listColors,
        listNames: listNames,
        fallback: fallback,
      );
      if (entry.isScheduled) {
        scheduled.add(entry);
      } else if (entry.isCompleted) {
        completed.add(entry);
      } else {
        unscheduled.add(entry);
      }
    }

    scheduled.sort((a, b) {
      final byStart = a.startMinuteOfDay.compareTo(b.startMinuteOfDay);
      if (byStart != 0) return byStart;
      return a.task.position.compareTo(b.task.position);
    });
    unscheduled.sort((a, b) => a.task.position.compareTo(b.task.position));
    completed.sort((a, b) {
      final aDate = a.task.completedAt ?? a.task.updatedAt;
      final bDate = b.task.completedAt ?? b.task.updatedAt;
      return bDate.compareTo(aDate);
    });

    return PlannedDay(
      date: dayOf(date),
      scheduled: scheduled,
      unscheduled: unscheduled,
      completed: completed,
    );
  }

  /// Up to [max] colors previewing a day inside the week strip.
  static List<Color> dayDots(
    DateTime date, {
    required List<TodoTask> tasks,
    required List<TaskList> lists,
    required Color fallback,
    int max = 4,
  }) {
    final listColors = <String, int>{
      for (final list in lists) list.id: list.color,
    };
    final dots = <Color>[];
    final sorted = tasks.where((t) => belongsToDay(t, date)).toList()
      ..sort((a, b) {
        final aMinute = a.startAt == null
            ? 1 << 20
            : a.startAt!.hour * 60 + a.startAt!.minute;
        final bMinute = b.startAt == null
            ? 1 << 20
            : b.startAt!.hour * 60 + b.startAt!.minute;
        return aMinute.compareTo(bMinute);
      });
    for (final task in sorted) {
      if (dots.length >= max) break;
      dots.add(colorFor(task, listColors, fallback));
    }
    return dots;
  }

  /// Free windows between the scheduled entries of [day].
  static List<PlannedGap> gapsOf(PlannedDay day) {
    final gaps = <PlannedGap>[];
    for (var i = 0; i < day.scheduled.length - 1; i++) {
      final end = day.scheduled[i].end;
      final next = day.scheduled[i + 1].start;
      if (end == null || next == null) continue;
      final minutes = next.difference(end).inMinutes;
      if (minutes >= minGapMinutes) {
        gaps.add(PlannedGap(start: end, minutes: minutes));
      }
    }
    return gaps;
  }

  /// First slot of [minutes] that does not collide with the scheduled work of
  /// [day]. Used when a task is moved from the inbox onto the timeline.
  static DateTime nextFreeSlot(
    PlannedDay day, {
    required int minutes,
    DateTime? now,
  }) {
    final base = day.date;
    var cursor = DateTime(base.year, base.month, base.day)
        .add(const Duration(minutes: dayStartMinute));
    final clock = now ?? DateTime.now();
    if (isSameDay(base, clock) && clock.isAfter(cursor)) {
      cursor = roundToQuarter(clock);
    }
    for (final entry in day.scheduled) {
      final start = entry.start;
      final end = entry.end;
      if (start == null || end == null) continue;
      if (end.isBefore(cursor) || end.isAtSameMomentAs(cursor)) continue;
      final free = start.difference(cursor).inMinutes;
      if (free >= minutes) return cursor;
      cursor = end;
    }
    return cursor;
  }

  static DateTime roundToQuarter(DateTime value) {
    final rounded = ((value.minute + 14) ~/ 15) * 15;
    return DateTime(value.year, value.month, value.day, value.hour)
        .add(Duration(minutes: rounded));
  }

  /// Capsule height in logical pixels for a task of [minutes].
  static double capsuleHeight(int minutes, {double scale = 1}) {
    final raw = 44 + (minutes / 60) * 64 * scale;
    return raw.clamp(44.0, 220.0);
  }

  /// Visible time window of a week grid, snapped to whole hours.
  static (int startMinute, int endMinute) weekWindow(
    Iterable<PlannedEntry> entries,
  ) {
    var start = dayStartMinute;
    var end = dayEndMinute;
    for (final entry in entries) {
      if (!entry.isScheduled) continue;
      start = start < entry.startMinuteOfDay ? start : entry.startMinuteOfDay;
      end = end > entry.endMinuteOfDay ? end : entry.endMinuteOfDay;
    }
    start = (start ~/ 60) * 60;
    end = ((end + 59) ~/ 60) * 60;
    if (end <= start) end = start + 60;
    return (start, end.clamp(start + 60, 24 * 60));
  }
}
