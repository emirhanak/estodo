import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../features/tasks/data/models/task_dto.dart';
import '../../features/tasks/data/models/task_list_dto.dart';
import '../../features/tasks/domain/entities/task_list.dart';
import '../../features/tasks/domain/entities/todo_task.dart';
import '../../features/tasks/presentation/providers/task_providers.dart';

@immutable
class BackupRestoreResult {
  const BackupRestoreResult({
    required this.restoredTasksCount,
    required this.restoredListsCount,
  });

  final int restoredTasksCount;
  final int restoredListsCount;
}

class BackupService {
  const BackupService._();

  static String exportToJson({
    required List<TodoTask> tasks,
    required List<TaskList> lists,
  }) {
    final payload = <String, dynamic>{
      'app': 'estodo',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'lists': lists.map((l) => TaskListDto.toLocal(l)).toList(),
      'tasks': tasks.map((t) => TaskDto.toLocal(t)).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Future<BackupRestoreResult> importFromJson(
    String jsonString, {
    required TaskController controller,
    required List<TaskList> existingLists,
    required List<TodoTask> existingTasks,
  }) async {
    final decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic> || decoded['tasks'] is! List) {
      throw const FormatException('Invalid backup payload');
    }

    final rawLists = decoded['lists'] as List<dynamic>? ?? const <dynamic>[];
    final rawTasks = decoded['tasks'] as List<dynamic>;

    // 1. Restore / map lists
    final listIdMap = <String, String>{};
    var restoredLists = 0;

    for (final item in rawLists) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final oldId = map['id'] as String? ?? '';
      final name = map['name'] as String? ?? 'List';
      final color = (map['color'] as num?)?.toInt() ?? 0xFF8E8CD8;

      final match = existingLists
          .where((l) => l.name.toLowerCase() == name.toLowerCase())
          .firstOrNull;
      if (match != null) {
        if (oldId.isNotEmpty) listIdMap[oldId] = match.id;
      } else {
        final newList = await controller.createList(name, color);
        restoredLists++;
        if (oldId.isNotEmpty) listIdMap[oldId] = newList.id;
      }
    }

    // 2. Restore tasks
    var restoredTasks = 0;
    for (final item in rawTasks) {
      if (item is! Map) continue;
      final parsed = TaskDto.fromLocal(
        item['id'] as String? ?? '',
        Map<String, dynamic>.from(item),
      );

      if (parsed.title.trim().isEmpty) continue;

      final mappedListId =
          parsed.listId != null && listIdMap.containsKey(parsed.listId)
              ? listIdMap[parsed.listId]
              : (existingLists.any((l) => l.id == parsed.listId)
                  ? parsed.listId
                  : null);

      await controller.createTask(
        title: parsed.title,
        notes: parsed.notes,
        listId: mappedListId,
        iconKey: parsed.iconKey,
        colorValue: parsed.colorValue,
        isHabit: parsed.isHabit,
        priority: parsed.priority,
        dueAt: parsed.dueAt,
        startAt: parsed.startAt,
        durationMinutes: parsed.durationMinutes,
        reminderAt: parsed.reminderAt,
        recurrence: parsed.recurrence,
        steps: parsed.steps,
        tags: parsed.tags,
        isImportant: parsed.isImportant,
        isMyDay: parsed.isMyDay,
      );
      restoredTasks++;
    }

    return BackupRestoreResult(
      restoredTasksCount: restoredTasks,
      restoredListsCount: restoredLists,
    );
  }
}
