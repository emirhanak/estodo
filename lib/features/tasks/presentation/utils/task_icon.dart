import 'package:flutter/material.dart';

import '../../domain/entities/task_priority.dart';
import '../../domain/entities/todo_task.dart';
import 'task_icon_catalog.dart';

/// Resolves the glyph a task shows on the planned timeline: the icon the user
/// picked, otherwise one suggested from the title.
class TaskIcons {
  const TaskIcons._();

  static IconData forTask(TodoTask task) {
    final chosen = TaskIconCatalog.entryFor(task.iconKey);
    if (chosen != null) return chosen.icon;
    return TaskIconCatalog.resolve(suggestKey(task));
  }

  /// Best guess icon key for [task] based on its title, then its flags.
  static String suggestKey(TodoTask task) {
    final suggestions = TaskIconCatalog.suggestKeys(task.title, max: 1);
    if (suggestions.isNotEmpty) return suggestions.first;
    if (task.isHabit || task.recurrence != null) return 'repeat';
    if (task.isImportant) return 'star';
    return switch (task.priority) {
      TaskPriority.high => 'flag',
      TaskPriority.medium => TaskIconCatalog.fallbackKey,
      TaskPriority.low => 'checklist',
    };
  }

  /// Ordered icon keys to offer while the user types [title].
  static List<String> suggestKeysForTitle(String title, {int max = 6}) {
    final keys = TaskIconCatalog.suggestKeys(title, max: max);
    if (keys.isNotEmpty) return keys;
    return const ['check', 'star', 'bolt', 'checklist', 'alarm', 'flag'];
  }
}
