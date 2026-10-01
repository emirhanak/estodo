import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/todo_task.dart';
import '../providers/task_providers.dart';

/// Holds calculated streak information across tasks and individual habits.
class StreakSummary {
  const StreakSummary({
    required this.currentStreak,
    required this.bestStreak,
    required this.completedToday,
    required this.weekCompletedDays,
    required this.weekCompletedCount,
    required this.habitStreaks,
  });

  static const empty = StreakSummary(
    currentStreak: 0,
    bestStreak: 0,
    completedToday: false,
    weekCompletedDays: <int>{},
    weekCompletedCount: 0,
    habitStreaks: <String, int>{},
  );

  /// Current active consecutive-day streak.
  final int currentStreak;

  /// All-time best consecutive-day streak.
  final int bestStreak;

  /// True if at least one task has been completed on the reference day (today).
  final bool completedToday;

  /// Set of weekday numbers (1 for Monday .. 7 for Sunday) that have completed tasks this week.
  final Set<int> weekCompletedDays;

  /// Total count of tasks completed in the current week.
  final int weekCompletedCount;

  /// Current streak for individual habits, keyed by lowercase title.
  final Map<String, int> habitStreaks;

  /// Gets the streak count for a specific habit task.
  int habitStreak(TodoTask task) {
    if (!task.isHabit) return 0;
    return habitStreaks[task.title.trim().toLowerCase()] ?? 0;
  }
}

class StreakCalculator {
  const StreakCalculator._();

  static StreakSummary compute(List<TodoTask> tasks, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);

    final completedTasks = tasks.where((t) => t.isCompleted).toList();
    if (completedTasks.isEmpty) {
      return StreakSummary.empty;
    }

    // 1. Group all completed days
    final activeDays = <DateTime>{};
    final habitDays = <String, Set<DateTime>>{};

    for (final task in completedTasks) {
      final date = task.completedAt ?? task.dueAt ?? task.updatedAt;
      final day = DateTime(date.year, date.month, date.day);
      activeDays.add(day);

      if (task.isHabit) {
        final key = task.title.trim().toLowerCase();
        habitDays.putIfAbsent(key, () => <DateTime>{}).add(day);
      }
    }

    // 2. Compute current and best streak for all tasks
    final currentStreak = _computeCurrentStreak(activeDays, today);
    final bestStreak = _computeBestStreak(activeDays, currentStreak);
    final completedToday = activeDays.contains(today);

    // 3. Compute week completions
    // Monday of current week
    final mondayOffset = (today.weekday - DateTime.monday) % 7;
    final monday = today.subtract(Duration(days: mondayOffset));
    final weekCompletedDays = <int>{};
    var weekCompletedCount = 0;

    for (var i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      if (activeDays.contains(day)) {
        weekCompletedDays.add(day.weekday);
      }
    }

    for (final task in completedTasks) {
      final date = task.completedAt ?? task.dueAt ?? task.updatedAt;
      final day = DateTime(date.year, date.month, date.day);
      if (!day.isBefore(monday) &&
          day.isBefore(monday.add(const Duration(days: 7)))) {
        weekCompletedCount++;
      }
    }

    // 4. Compute per-habit streaks
    final habitStreaks = <String, int>{};
    for (final entry in habitDays.entries) {
      habitStreaks[entry.key] = _computeCurrentStreak(entry.value, today);
    }

    return StreakSummary(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      completedToday: completedToday,
      weekCompletedDays: weekCompletedDays,
      weekCompletedCount: weekCompletedCount,
      habitStreaks: habitStreaks,
    );
  }

  static int _computeCurrentStreak(Set<DateTime> days, DateTime today) {
    if (days.isEmpty) return 0;

    var count = 0;
    var checkDay = today;

    // If today is completed, start from today.
    // If today is not completed yet, check if yesterday was completed.
    if (days.contains(checkDay)) {
      count = 1;
      checkDay = checkDay.subtract(const Duration(days: 1));
    } else {
      checkDay = checkDay.subtract(const Duration(days: 1));
      if (!days.contains(checkDay)) {
        return 0;
      }
      count = 1;
      checkDay = checkDay.subtract(const Duration(days: 1));
    }

    while (days.contains(checkDay)) {
      count++;
      checkDay = checkDay.subtract(const Duration(days: 1));
    }

    return count;
  }

  static int _computeBestStreak(Set<DateTime> days, int currentStreak) {
    if (days.isEmpty) return 0;

    final sorted = days.toList()..sort();
    var maxStreak = 1;
    var currentChain = 1;

    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];
      final diff = curr.difference(prev).inDays;

      if (diff == 1) {
        currentChain++;
        if (currentChain > maxStreak) {
          maxStreak = currentChain;
        }
      } else if (diff > 1) {
        currentChain = 1;
      }
    }

    return maxStreak > currentStreak ? maxStreak : currentStreak;
  }
}

/// Provider that calculates the user's current streak statistics dynamically.
final streakProvider = Provider<StreakSummary>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const <TodoTask>[];
  return StreakCalculator.compute(tasks);
});
