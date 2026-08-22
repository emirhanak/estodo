import 'recurrence_rule.dart';
import 'task_priority.dart';
import 'task_step.dart';

class TodoTask {
  const TodoTask({
    required this.id,
    required this.userId,
    this.listId,
    required this.title,
    this.notes,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.startAt,
    this.durationMinutes,
    this.reminderAt,
    this.recurrence,
    this.steps = const <TaskStep>[],
    this.isCompleted = false,
    this.isImportant = false,
    this.isMyDay = false,
    this.myDayDate,
    this.completedAt,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? listId;
  final String title;
  final String? notes;
  final TaskPriority priority;
  final DateTime? dueAt;
  final DateTime? startAt;
  final int? durationMinutes;
  final DateTime? reminderAt;
  final RecurrenceRule? recurrence;
  final List<TaskStep> steps;
  final bool isCompleted;
  final bool isImportant;
  final bool isMyDay;
  final String? myDayDate;
  final DateTime? completedAt;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isInMyDay(String todayKey) => isMyDay && myDayDate == todayKey;

  int get completedStepsCount => steps.where((step) => step.isCompleted).length;

  bool get hasSteps => steps.isNotEmpty;

  TodoTask copyWith({
    String? id,
    String? userId,
    Object? listId = _unset,
    String? title,
    Object? notes = _unset,
    TaskPriority? priority,
    Object? dueAt = _unset,
    Object? startAt = _unset,
    Object? durationMinutes = _unset,
    Object? reminderAt = _unset,
    Object? recurrence = _unset,
    List<TaskStep>? steps,
    bool? isCompleted,
    bool? isImportant,
    bool? isMyDay,
    Object? myDayDate = _unset,
    Object? completedAt = _unset,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      listId: listId == _unset ? this.listId : listId as String?,
      title: title ?? this.title,
      notes: notes == _unset ? this.notes : notes as String?,
      priority: priority ?? this.priority,
      dueAt: dueAt == _unset ? this.dueAt : dueAt as DateTime?,
      startAt: startAt == _unset ? this.startAt : startAt as DateTime?,
      durationMinutes: durationMinutes == _unset
          ? this.durationMinutes
          : durationMinutes as int?,
      reminderAt:
          reminderAt == _unset ? this.reminderAt : reminderAt as DateTime?,
      recurrence: recurrence == _unset
          ? this.recurrence
          : recurrence as RecurrenceRule?,
      steps: steps ?? this.steps,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      isMyDay: isMyDay ?? this.isMyDay,
      myDayDate: myDayDate == _unset ? this.myDayDate : myDayDate as String?,
      completedAt:
          completedAt == _unset ? this.completedAt : completedAt as DateTime?,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const _unset = Object();
