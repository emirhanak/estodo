import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estodo/features/tasks/data/models/task_dto.dart';
import 'package:estodo/features/tasks/data/models/task_list_dto.dart';
import 'package:estodo/features/tasks/domain/entities/list_sort_option.dart';
import 'package:estodo/features/tasks/domain/entities/recurrence_rule.dart';
import 'package:estodo/features/tasks/domain/entities/task_list.dart';
import 'package:estodo/features/tasks/domain/entities/task_priority.dart';
import 'package:estodo/features/tasks/domain/entities/task_step.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:flutter_test/flutter_test.dart';

final _created = DateTime(2026, 10, 1, 8);
final _updated = DateTime(2026, 10, 2, 9, 15);

TodoTask _fullTask() => TodoTask(
      id: 'task-1',
      userId: 'u',
      listId: 'list-1',
      title: 'Write report',
      notes: 'Section 2 first',
      iconKey: 'book',
      colorValue: 0xFF123456,
      isHabit: true,
      priority: TaskPriority.high,
      dueAt: DateTime(2026, 10, 5, 17),
      startAt: DateTime(2026, 10, 5, 15),
      durationMinutes: 90,
      reminderAt: DateTime(2026, 10, 5, 14, 45),
      recurrence: const RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        weekdays: [DateTime.monday],
      ),
      steps: const [
        TaskStep(id: 's1', title: 'Outline', isCompleted: true),
        TaskStep(id: 's2', title: 'Draft'),
      ],
      tags: const ['work', 'q4'],
      isCompleted: true,
      isImportant: true,
      isMyDay: true,
      myDayDate: '2026-10-05',
      completedAt: DateTime(2026, 10, 5, 18),
      position: 3,
      createdAt: _created,
      updatedAt: _updated,
    );

void _expectSameTask(TodoTask actual, TodoTask expected) {
  expect(actual.id, expected.id);
  expect(actual.listId, expected.listId);
  expect(actual.title, expected.title);
  expect(actual.notes, expected.notes);
  expect(actual.iconKey, expected.iconKey);
  expect(actual.colorValue, expected.colorValue);
  expect(actual.isHabit, expected.isHabit);
  expect(actual.priority, expected.priority);
  expect(actual.dueAt, expected.dueAt);
  expect(actual.startAt, expected.startAt);
  expect(actual.durationMinutes, expected.durationMinutes);
  expect(actual.reminderAt, expected.reminderAt);
  expect(actual.recurrence?.frequency, expected.recurrence?.frequency);
  expect(actual.recurrence?.weekdays, expected.recurrence?.weekdays);
  expect(
    actual.steps.map((s) => [s.id, s.title, s.isCompleted]),
    expected.steps.map((s) => [s.id, s.title, s.isCompleted]),
  );
  expect(actual.tags, expected.tags);
  expect(actual.isCompleted, expected.isCompleted);
  expect(actual.isImportant, expected.isImportant);
  expect(actual.isMyDay, expected.isMyDay);
  expect(actual.myDayDate, expected.myDayDate);
  expect(actual.completedAt, expected.completedAt);
  expect(actual.position, expected.position);
  expect(actual.createdAt, expected.createdAt);
  expect(actual.updatedAt, expected.updatedAt);
}

void main() {
  group('TaskDto', () {
    test('round-trips every field through the local format', () {
      final task = _fullTask();
      _expectSameTask(
        TaskDto.fromLocal(task.id, TaskDto.toLocal(task)),
        task,
      );
    });

    test('round-trips every field through the Firestore format', () {
      final task = _fullTask();
      final data = TaskDto.toFirestore(task);
      expect(data['updatedAt'], isA<Timestamp>());
      _expectSameTask(TaskDto.fromMap(task.id, data), task);
    });

    test('fills defaults for a sparse document', () {
      final task = TaskDto.fromMap('sparse', {'title': 'Only a title'});
      expect(task.id, 'sparse');
      expect(task.title, 'Only a title');
      expect(task.steps, isEmpty);
      expect(task.tags, isEmpty);
      expect(task.isCompleted, isFalse);
      expect(task.recurrence, isNull);
    });
  });

  group('TaskListDto', () {
    final list = TaskList(
      id: 'list-1',
      userId: 'u',
      name: 'Groceries',
      color: 0xFF00AA00,
      sortOption: ListSortOption.dueDate,
      sortAscending: false,
      position: 2,
      groupId: 'g',
      background: 'forest',
      createdAt: _created,
      updatedAt: _updated,
    );

    void expectSameList(TaskList actual) {
      expect(actual.id, list.id);
      expect(actual.name, list.name);
      expect(actual.color, list.color);
      expect(actual.sortOption, list.sortOption);
      expect(actual.sortAscending, list.sortAscending);
      expect(actual.position, list.position);
      expect(actual.groupId, list.groupId);
      expect(actual.background, list.background);
      expect(actual.createdAt, list.createdAt);
      expect(actual.updatedAt, list.updatedAt);
    }

    test('round-trips through the local format', () {
      expectSameList(TaskListDto.fromLocal(list.id, TaskListDto.toLocal(list)));
    });

    test('round-trips through the Firestore format', () {
      expectSameList(
        TaskListDto.fromMap(list.id, TaskListDto.toFirestore(list)),
      );
    });

    test('falls back to manual sorting for unknown values', () {
      final restored = TaskListDto.fromMap('x', {
        ...TaskListDto.toLocal(list),
        'sortOption': 'mystery',
      });
      expect(restored.sortOption, ListSortOption.manual);
    });
  });

  test('TaskStep copies and serializes', () {
    const step = TaskStep(id: 's', title: 'Call');
    final done = step.copyWith(isCompleted: true);
    expect(done.title, 'Call');
    expect(done.isCompleted, isTrue);
    final restored = TaskStep.fromMap(done.toMap());
    expect([restored.id, restored.title, restored.isCompleted],
        ['s', 'Call', true]);
    expect(TaskStep.fromMap(const {}).title, '');
  });

  test('every sort option has a label', () {
    for (final option in ListSortOption.values) {
      expect(option.label, isNotEmpty);
    }
  });
}
