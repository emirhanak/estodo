import 'package:estodo/features/tasks/domain/entities/task_priority.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/presentation/utils/planned_layout.dart';
import 'package:estodo/features/tasks/presentation/utils/planned_smart_planner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime(2026, 8, 22);

  TodoTask task(
    String id, {
    DateTime? start,
    int duration = 30,
    TaskPriority priority = TaskPriority.medium,
    bool important = false,
    int position = 0,
  }) =>
      TodoTask(
        id: id,
        userId: 'u',
        title: id,
        dueAt: date,
        startAt: start,
        durationMinutes: duration,
        priority: priority,
        isImportant: important,
        position: position,
        createdAt: date,
        updatedAt: date,
      );

  PlannedDay dayOf(List<TodoTask> tasks) => PlannedLayout.buildDay(
        date: date,
        tasks: tasks,
        lists: const [],
        fallback: Colors.blue,
      );

  test('places important and high priority tasks first without overlap', () {
    final day = dayOf([
      task('occupied', start: DateTime(2026, 8, 22, 8), duration: 60),
      task('low', priority: TaskPriority.low, position: 1),
      task('high', priority: TaskPriority.high, duration: 45, position: 2),
      task('important', important: true, position: 3),
    ]);

    final plan = PlannedSmartPlanner.plan(
      day,
      now: DateTime(2026, 8, 21, 12),
    );

    expect(plan.map((item) => item.task.id), ['important', 'high', 'low']);
    expect(plan[0].start, DateTime(2026, 8, 22, 7));
    expect(plan[1].start, DateTime(2026, 8, 22, 9));
    expect(plan[2].start, DateTime(2026, 8, 22, 7, 30));
  });

  test('does not place work beyond the planning day', () {
    final day = dayOf([
      task('occupied', start: DateTime(2026, 8, 22, 7), duration: 14 * 60),
      task('too-long', duration: 120),
    ]);

    expect(PlannedSmartPlanner.plan(day, now: DateTime(2026, 8, 21)), isEmpty);
  });
}
