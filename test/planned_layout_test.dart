import 'package:estodo/features/tasks/domain/entities/task_list.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/presentation/utils/planned_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 8, 22);
  const accent = Color(0xFF8E8CD8);

  TaskList list(String id, int color) => TaskList(
        id: id,
        userId: 'u',
        name: 'list-$id',
        color: color,
        createdAt: day,
        updatedAt: day,
      );

  TodoTask task(
    String id, {
    DateTime? due,
    DateTime? start,
    int? duration,
    String? listId,
    bool completed = false,
    int position = 0,
  }) =>
      TodoTask(
        id: id,
        userId: 'u',
        title: 'task $id',
        listId: listId,
        dueAt: due ?? day,
        startAt: start,
        durationMinutes: duration,
        isCompleted: completed,
        position: position,
        createdAt: day,
        updatedAt: day,
      );

  group('weekStart', () {
    test('starts on Monday when the locale is Monday-first', () {
      final start = PlannedLayout.weekStart(day, mondayFirst: true);
      expect(start, DateTime(2026, 8, 17));
      expect(start.weekday, DateTime.monday);
    });

    test('starts on Sunday when the locale is Sunday-first', () {
      final start = PlannedLayout.weekStart(day, mondayFirst: false);
      expect(start, DateTime(2026, 8, 16));
      expect(start.weekday, DateTime.sunday);
    });

    test('weekDays returns seven consecutive days', () {
      final days = PlannedLayout.weekDays(DateTime(2026, 8, 17));
      expect(days.length, 7);
      expect(days.last, DateTime(2026, 8, 23));
    });
  });

  group('buildDay', () {
    test('splits scheduled, unscheduled and completed tasks', () {
      final result = PlannedLayout.buildDay(
        date: day,
        tasks: [
          task('a', start: DateTime(2026, 8, 22, 9)),
          task('b'),
          task('c', completed: true),
          task('d', due: DateTime(2026, 8, 23)),
        ],
        lists: const <TaskList>[],
        fallback: accent,
      );

      expect(result.scheduled.map((e) => e.task.id), ['a']);
      expect(result.unscheduled.map((e) => e.task.id), ['b']);
      expect(result.completed.map((e) => e.task.id), ['c']);
      expect(result.totalCount, 3);
      expect(result.doneCount, 1);
    });

    test('orders scheduled tasks by start time', () {
      final result = PlannedLayout.buildDay(
        date: day,
        tasks: [
          task('late', start: DateTime(2026, 8, 22, 17)),
          task('early', start: DateTime(2026, 8, 22, 8, 30)),
        ],
        lists: const <TaskList>[],
        fallback: accent,
      );
      expect(result.scheduled.map((e) => e.task.id), ['early', 'late']);
    });

    test('resolves the list color and falls back to the accent', () {
      final result = PlannedLayout.buildDay(
        date: day,
        tasks: [
          task('a', start: DateTime(2026, 8, 22, 9), listId: 'l1'),
          task('b', start: DateTime(2026, 8, 22, 10)),
        ],
        lists: [list('l1', 0xFF107C10)],
        fallback: accent,
      );
      expect(result.scheduled.first.color, const Color(0xFF107C10));
      expect(result.scheduled.first.listName, 'list-l1');
      expect(result.scheduled.last.color, accent);
    });

    test('plannedMinutes ignores completed work', () {
      final result = PlannedLayout.buildDay(
        date: day,
        tasks: [
          task('a', start: DateTime(2026, 8, 22, 9), duration: 45),
          task('b',
              start: DateTime(2026, 8, 22, 11), duration: 30, completed: true),
        ],
        lists: const <TaskList>[],
        fallback: accent,
      );
      expect(result.plannedMinutes, 45);
    });
  });

  group('entry geometry', () {
    test('falls back to the default duration', () {
      final entry = PlannedLayout.entryOf(
        task('a', start: DateTime(2026, 8, 22, 9)),
        listColors: const {},
        listNames: const {},
        fallback: accent,
      );
      expect(entry.durationMinutes, PlannedLayout.defaultDurationMinutes);
      expect(entry.end, DateTime(2026, 8, 22, 9, 30));
      expect(entry.startMinuteOfDay, 9 * 60);
    });

    test('reports progress and remaining time while running', () {
      final entry = PlannedLayout.entryOf(
        task('a', start: DateTime(2026, 8, 22, 9), duration: 60),
        listColors: const {},
        listNames: const {},
        fallback: accent,
      );
      final now = DateTime(2026, 8, 22, 9, 15);
      expect(entry.isActiveAt(now), isTrue);
      expect(entry.progressAt(now), closeTo(0.25, 0.001));
      expect(entry.remainingMinutesAt(now), 45);
      expect(entry.isActiveAt(DateTime(2026, 8, 22, 10, 1)), isFalse);
    });

    test('completed tasks are never active', () {
      final entry = PlannedLayout.entryOf(
        task('a',
            start: DateTime(2026, 8, 22, 9), duration: 60, completed: true),
        listColors: const {},
        listNames: const {},
        fallback: accent,
      );
      expect(entry.isActiveAt(DateTime(2026, 8, 22, 9, 15)), isFalse);
    });

    test('capsule height grows with duration and stays clamped', () {
      expect(PlannedLayout.capsuleHeight(15), 60);
      expect(
        PlannedLayout.capsuleHeight(60),
        greaterThan(PlannedLayout.capsuleHeight(30)),
      );
      expect(PlannedLayout.capsuleHeight(600), 220);
    });
  });

  group('free time', () {
    PlannedDay dayWith(List<TodoTask> tasks) => PlannedLayout.buildDay(
          date: day,
          tasks: tasks,
          lists: const <TaskList>[],
          fallback: accent,
        );

    test('ignores gaps shorter than the minimum', () {
      final gaps = PlannedLayout.gapsOf(
        dayWith([
          task('a', start: DateTime(2026, 8, 22, 9), duration: 30),
          task('b', start: DateTime(2026, 8, 22, 9, 40), duration: 30),
        ]),
      );
      expect(gaps, isEmpty);
    });

    test('reports the length of a real gap', () {
      final gaps = PlannedLayout.gapsOf(
        dayWith([
          task('a', start: DateTime(2026, 8, 22, 9), duration: 30),
          task('b', start: DateTime(2026, 8, 22, 11), duration: 30),
        ]),
      );
      expect(gaps.length, 1);
      expect(gaps.single.start, DateTime(2026, 8, 22, 9, 30));
      expect(gaps.single.minutes, 90);
    });

    test('nextFreeSlot starts at the day start on an empty day', () {
      final slot = PlannedLayout.nextFreeSlot(
        dayWith(const <TodoTask>[]),
        minutes: 30,
        now: DateTime(2026, 8, 21, 12),
      );
      expect(slot, DateTime(2026, 8, 22, 7));
    });

    test('nextFreeSlot skips busy blocks', () {
      final slot = PlannedLayout.nextFreeSlot(
        dayWith([
          task('a', start: DateTime(2026, 8, 22, 7), duration: 60),
          task('b', start: DateTime(2026, 8, 22, 8), duration: 60),
        ]),
        minutes: 30,
        now: DateTime(2026, 8, 21, 12),
      );
      expect(slot, DateTime(2026, 8, 22, 9));
    });

    test('nextFreeSlot never suggests a past time today', () {
      final now = DateTime(2026, 8, 22, 13, 7);
      final slot = PlannedLayout.nextFreeSlot(
        dayWith(const <TodoTask>[]),
        minutes: 30,
        now: now,
      );
      expect(slot, DateTime(2026, 8, 22, 13, 15));
    });

    test('roundToQuarter rounds up to the next quarter hour', () {
      expect(
        PlannedLayout.roundToQuarter(DateTime(2026, 8, 22, 9, 1)),
        DateTime(2026, 8, 22, 9, 15),
      );
      expect(
        PlannedLayout.roundToQuarter(DateTime(2026, 8, 22, 9, 46)),
        DateTime(2026, 8, 22, 10),
      );
    });
  });

  group('week window', () {
    test('defaults to the 07:00–22:00 band', () {
      final (start, end) = PlannedLayout.weekWindow(const <PlannedEntry>[]);
      expect(start, 7 * 60);
      expect(end, 22 * 60);
    });

    test('expands to cover early and late tasks', () {
      final entries = [
        PlannedLayout.entryOf(
          task('a', start: DateTime(2026, 8, 22, 5, 30), duration: 30),
          listColors: const {},
          listNames: const {},
          fallback: accent,
        ),
        PlannedLayout.entryOf(
          task('b', start: DateTime(2026, 8, 22, 22, 30), duration: 60),
          listColors: const {},
          listNames: const {},
          fallback: accent,
        ),
      ];
      final (start, end) = PlannedLayout.weekWindow(entries);
      expect(start, 5 * 60);
      expect(end, 24 * 60);
    });
  });

  group('day dots', () {
    test('previews at most four task colors, timed first', () {
      final dots = PlannedLayout.dayDots(
        day,
        tasks: [
          task('a', listId: 'l1'),
          task('b', start: DateTime(2026, 8, 22, 8), listId: 'l2'),
          task('c', start: DateTime(2026, 8, 22, 9)),
          task('d', start: DateTime(2026, 8, 22, 10)),
          task('e', start: DateTime(2026, 8, 22, 11)),
        ],
        lists: [list('l1', 0xFF107C10), list('l2', 0xFF0078D4)],
        fallback: accent,
      );
      expect(dots.length, 4);
      expect(dots.first, const Color(0xFF0078D4));
    });

    test('is empty for a day without tasks', () {
      expect(
        PlannedLayout.dayDots(
          DateTime(2026, 8, 25),
          tasks: [task('a')],
          lists: const <TaskList>[],
          fallback: accent,
        ),
        isEmpty,
      );
    });
  });

  group('pagination', () {
    test('page index and date round-trip', () {
      final index = PlannedLayout.pageIndexOf(day);
      expect(PlannedLayout.dateOfPage(index), day);
      expect(
        PlannedLayout.dateOfPage(index + 1),
        DateTime(2026, 8, 23),
      );
    });
  });
}
