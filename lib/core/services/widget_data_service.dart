import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/tasks/domain/entities/todo_task.dart';
import '../../features/tasks/presentation/providers/task_providers.dart';
import '../../features/tasks/presentation/utils/planned_layout.dart';
import '../../features/tasks/presentation/utils/streak_calculator.dart';
import '../utils/date_time_formatter.dart';
import 'preferences_provider.dart';

class WidgetDataService {
  const WidgetDataService._();

  static const String prefKey = 'estodo.widget.summary';

  static Future<void> updateSnapshot({
    required SharedPreferences prefs,
    required List<TodoTask> tasks,
    required StreakSummary streakSummary,
  }) async {
    final now = DateTime.now();
    final todayKey = DateTimeFormatter.todayKey(now);

    final todayTasks = tasks.where((t) {
      if (t.dueAt != null && PlannedLayout.isSameDay(t.dueAt!, now)) return true;
      if (t.isMyDay && t.myDayDate == todayKey) return true;
      if (t.startAt != null && PlannedLayout.isSameDay(t.startAt!, now)) return true;
      return false;
    }).toList();

    final completedCount = todayTasks.where((t) => t.isCompleted).length;
    final pendingCount = todayTasks.length - completedCount;

    final scheduledToday = todayTasks
        .where((t) => !t.isCompleted && t.startAt != null)
        .toList()
      ..sort((a, b) => a.startAt!.compareTo(b.startAt!));

    final nextUpcoming = scheduledToday.firstOrNull;

    final snapshot = {
      'updatedAt': now.toIso8601String(),
      'streakDays': streakSummary.currentStreak,
      'todayTotalCount': todayTasks.length,
      'todayCompletedCount': completedCount,
      'todayPendingCount': pendingCount,
      'completionRatio':
          todayTasks.isEmpty ? 0.0 : (completedCount / todayTasks.length),
      'nextUpcoming': nextUpcoming == null
          ? null
          : {
              'title': nextUpcoming.title,
              'startAt': nextUpcoming.startAt?.toIso8601String(),
              'durationMinutes': nextUpcoming.durationMinutes ?? 30,
              'iconKey': nextUpcoming.iconKey,
            },
      'todayTasks': [
        for (final t in todayTasks.take(5))
          {
            'id': t.id,
            'title': t.title,
            'isCompleted': t.isCompleted,
            'time': t.startAt != null
                ? '${t.startAt!.hour.toString().padLeft(2, '0')}:${t.startAt!.minute.toString().padLeft(2, '0')}'
                : null,
          }
      ],
    };

    await prefs.setString(prefKey, json.encode(snapshot));
  }
}

/// Provider that automatically synchronizes the widget snapshot whenever tasks or streak change
final widgetDataSyncProvider = Provider<void>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final streak = ref.watch(streakProvider);
  final prefsAsync = ref.watch(sharedPreferencesProvider);

  final tasks = tasksAsync.value;
  final prefs = prefsAsync.value;

  if (tasks != null && prefs != null) {
    WidgetDataService.updateSnapshot(
      prefs: prefs,
      tasks: tasks,
      streakSummary: streak,
    );
  }
});
