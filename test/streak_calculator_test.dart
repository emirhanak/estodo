import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/presentation/utils/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 28, 12, 0); // Monday

  TodoTask completedTask(String id, DateTime completedAt, {bool isHabit = false, String title = 'Task'}) {
    return TodoTask(
      id: id,
      userId: 'user1',
      title: title,
      isHabit: isHabit,
      isCompleted: true,
      completedAt: completedAt,
      createdAt: completedAt,
      updatedAt: completedAt,
    );
  }

  group('StreakCalculator', () {
    test('returns empty summary when no tasks are present', () {
      final summary = StreakCalculator.compute(const <TodoTask>[], now: now);
      expect(summary.currentStreak, 0);
      expect(summary.bestStreak, 0);
      expect(summary.completedToday, isFalse);
      expect(summary.weekCompletedDays, isEmpty);
      expect(summary.weekCompletedCount, 0);
    });

    test('counts 1 day streak when task completed today', () {
      final tasks = [
        completedTask('1', DateTime(2026, 9, 28, 9, 0)),
      ];
      final summary = StreakCalculator.compute(tasks, now: now);
      expect(summary.currentStreak, 1);
      expect(summary.bestStreak, 1);
      expect(summary.completedToday, isTrue);
      expect(summary.weekCompletedDays, contains(DateTime.monday));
      expect(summary.weekCompletedCount, 1);
    });

    test('maintains active streak from yesterday before completing tasks today', () {
      final tasks = [
        completedTask('1', DateTime(2026, 9, 27, 10, 0)), // Yesterday (Sunday)
        completedTask('2', DateTime(2026, 9, 26, 10, 0)), // 2 days ago (Saturday)
      ];
      final summary = StreakCalculator.compute(tasks, now: now);
      expect(summary.currentStreak, 2);
      expect(summary.bestStreak, 2);
      expect(summary.completedToday, isFalse);
    });

    test('streak increases when completed today after yesterday', () {
      final tasks = [
        completedTask('1', DateTime(2026, 9, 28, 10, 0)), // Today
        completedTask('2', DateTime(2026, 9, 27, 10, 0)), // Yesterday
        completedTask('3', DateTime(2026, 9, 26, 10, 0)), // 2 days ago
      ];
      final summary = StreakCalculator.compute(tasks, now: now);
      expect(summary.currentStreak, 3);
      expect(summary.bestStreak, 3);
      expect(summary.completedToday, isTrue);
    });

    test('streak resets to 0 if yesterday was missed', () {
      final tasks = [
        completedTask('1', DateTime(2026, 9, 26, 10, 0)), // 2 days ago (missed yesterday and today)
      ];
      final summary = StreakCalculator.compute(tasks, now: now);
      expect(summary.currentStreak, 0);
      expect(summary.bestStreak, 1);
      expect(summary.completedToday, isFalse);
    });

    test('computes historical best streak even if current streak is broken', () {
      final tasks = [
        // Chain of 4 days in August
        completedTask('1', DateTime(2026, 8, 10)),
        completedTask('2', DateTime(2026, 8, 11)),
        completedTask('3', DateTime(2026, 8, 12)),
        completedTask('4', DateTime(2026, 8, 13)),
        // Only 1 day recently
        completedTask('5', DateTime(2026, 9, 28)),
      ];
      final summary = StreakCalculator.compute(tasks, now: now);
      expect(summary.currentStreak, 1);
      expect(summary.bestStreak, 4);
    });

    test('tracks individual habit streaks', () {
      final tasks = [
        completedTask('1', DateTime(2026, 9, 28, 8, 0), isHabit: true, title: 'Yoga'),
        completedTask('2', DateTime(2026, 9, 27, 8, 0), isHabit: true, title: 'Yoga'),
        completedTask('3', DateTime(2026, 9, 28, 9, 0), isHabit: true, title: 'Kitap'),
      ];
      final summary = StreakCalculator.compute(tasks, now: now);
      expect(summary.habitStreaks['yoga'], 2);
      expect(summary.habitStreaks['kitap'], 1);
      expect(summary.habitStreak(tasks[0]), 2);
      expect(summary.habitStreak(tasks[2]), 1);
    });
  });
}
