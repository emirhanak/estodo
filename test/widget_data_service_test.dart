import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:estodo/core/services/widget_data_service.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/presentation/utils/streak_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WidgetDataService.updateSnapshot stores summary in SharedPreferences',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tasks = [
      TodoTask(
        id: 't1',
        userId: 'u1',
        title: 'Morning Yoga',
        dueAt: today,
        startAt: today.add(const Duration(hours: 8)),
        durationMinutes: 30,
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      ),
      TodoTask(
        id: 't2',
        userId: 'u1',
        title: 'Deep Coding',
        dueAt: today,
        startAt: today.add(const Duration(hours: 14)),
        durationMinutes: 60,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    const streakSummary = StreakSummary(
      currentStreak: 4,
      bestStreak: 7,
      completedToday: true,
      weekCompletedDays: {1, 2, 3, 4},
      weekCompletedCount: 6,
      habitStreaks: {},
    );

    await WidgetDataService.updateSnapshot(
      prefs: prefs,
      tasks: tasks,
      streakSummary: streakSummary,
    );

    final raw = prefs.getString(WidgetDataService.prefKey);
    expect(raw, isNotNull);

    final data = json.decode(raw!) as Map<String, dynamic>;
    expect(data['streakDays'], 4);
    expect(data['todayTotalCount'], 2);
    expect(data['todayCompletedCount'], 1);
    expect(data['todayPendingCount'], 1);
    expect(data['nextUpcoming'], isNotNull);
    expect(data['nextUpcoming']['title'], 'Deep Coding');
    expect(data['todayTasks'], hasLength(2));
  });
}
