import '../../domain/entities/todo_task.dart';
import 'planned_layout.dart';

typedef SmartPlanAssignment = ({TodoTask task, DateTime start});

class PlannedSmartPlanner {
  const PlannedSmartPlanner._();

  static List<SmartPlanAssignment> plan(PlannedDay day, {DateTime? now}) {
    final candidates = day.unscheduled.map((entry) => entry.task).toList()
      ..sort((a, b) {
        final important =
            (b.isImportant ? 1 : 0).compareTo(a.isImportant ? 1 : 0);
        if (important != 0) return important;
        final priority = b.priority.index.compareTo(a.priority.index);
        if (priority != 0) return priority;
        return a.position.compareTo(b.position);
      });
    final occupied = [
      for (final entry in day.scheduled)
        if (!entry.isCompleted && entry.start != null && entry.end != null)
          (start: entry.start!, end: entry.end!),
    ]..sort((a, b) => a.start.compareTo(b.start));
    final result = <SmartPlanAssignment>[];
    final base = PlannedLayout.dayOf(day.date);
    var earliest = base.add(
      const Duration(minutes: PlannedLayout.dayStartMinute),
    );
    final clock = now ?? DateTime.now();
    if (PlannedLayout.isSameDay(base, clock) && clock.isAfter(earliest)) {
      earliest = PlannedLayout.roundToQuarter(clock);
    }
    final limit = base.add(
      const Duration(minutes: PlannedLayout.dayEndMinute),
    );

    for (final task in candidates) {
      final duration = Duration(
        minutes: task.durationMinutes ?? PlannedLayout.defaultDurationMinutes,
      );
      var cursor = earliest;
      for (final block in occupied) {
        if (!block.end.isAfter(cursor)) continue;
        if (!block.start.isBefore(cursor.add(duration))) break;
        cursor = block.end;
      }
      if (cursor.add(duration).isAfter(limit)) continue;
      result.add((task: task, start: cursor));
      occupied.add((start: cursor, end: cursor.add(duration)));
      occupied.sort((a, b) => a.start.compareTo(b.start));
    }
    return result;
  }
}
