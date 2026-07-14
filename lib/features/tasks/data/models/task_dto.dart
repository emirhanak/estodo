import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/recurrence_rule.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_step.dart';
import '../../domain/entities/todo_task.dart';

class TaskDto {
  const TaskDto._();

  static TodoTask fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  static TodoTask fromLocal(String id, Map<dynamic, dynamic> data) {
    return fromMap(id, Map<String, dynamic>.from(data));
  }

  static TodoTask fromMap(String id, Map<String, dynamic> data) {
    return TodoTask(
      id: data['id'] as String? ?? id,
      userId: data['userId'] as String? ?? '',
      listId: data['listId'] as String?,
      title: data['title'] as String? ?? '',
      notes: data['notes'] as String?,
      priority: _priorityFromString(data['priority'] as String?),
      dueAt: _dateFrom(data['dueAt']),
      reminderAt: _dateFrom(data['reminderAt']),
      recurrence: _recurrenceFrom(data['recurrence']),
      steps: _stepsFrom(data['steps']),
      isCompleted: data['isCompleted'] as bool? ?? false,
      isImportant: data['isImportant'] as bool? ?? false,
      isMyDay: data['isMyDay'] as bool? ?? false,
      myDayDate: data['myDayDate'] as String?,
      completedAt: _dateFrom(data['completedAt']),
      position: (data['position'] as num?)?.toInt() ?? 0,
      createdAt: _dateFrom(data['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFrom(data['updatedAt']) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toFirestore(TodoTask task) {
    return {
      'id': task.id,
      'userId': task.userId,
      'listId': task.listId,
      'title': task.title,
      'notes': task.notes,
      'priority': task.priority.name,
      'dueAt': _timestamp(task.dueAt),
      'reminderAt': _timestamp(task.reminderAt),
      'recurrence': task.recurrence?.toMap(),
      'steps': task.steps.map((step) => step.toMap()).toList(),
      'isCompleted': task.isCompleted,
      'isImportant': task.isImportant,
      'isMyDay': task.isMyDay,
      'myDayDate': task.myDayDate,
      'completedAt': _timestamp(task.completedAt),
      'position': task.position,
      'createdAt': _timestamp(task.createdAt),
      'updatedAt': _timestamp(task.updatedAt),
    };
  }

  static Map<String, dynamic> toLocal(TodoTask task) {
    return {
      'id': task.id,
      'userId': task.userId,
      'listId': task.listId,
      'title': task.title,
      'notes': task.notes,
      'priority': task.priority.name,
      'dueAt': task.dueAt?.toIso8601String(),
      'reminderAt': task.reminderAt?.toIso8601String(),
      'recurrence': task.recurrence?.toMap(),
      'steps': task.steps.map((step) => step.toMap()).toList(),
      'isCompleted': task.isCompleted,
      'isImportant': task.isImportant,
      'isMyDay': task.isMyDay,
      'myDayDate': task.myDayDate,
      'completedAt': task.completedAt?.toIso8601String(),
      'position': task.position,
      'createdAt': task.createdAt.toIso8601String(),
      'updatedAt': task.updatedAt.toIso8601String(),
    };
  }

  static DateTime? _dateFrom(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Timestamp? _timestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }

  static TaskPriority _priorityFromString(String? value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => TaskPriority.medium,
    );
  }

  static RecurrenceRule? _recurrenceFrom(Object? value) {
    if (value == null) return null;
    if (value is Map) {
      return RecurrenceRule.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static List<TaskStep> _stepsFrom(Object? value) {
    if (value is! List) return const <TaskStep>[];
    return value
        .whereType<Map>()
        .map((entry) => TaskStep.fromMap(entry))
        .toList(growable: false);
  }
}
