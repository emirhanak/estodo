import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/firebase_providers.dart';
import '../../../../core/services/notification_provider.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/task_local_data_source.dart';
import '../../data/datasources/task_remote_data_source.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/list_sort_option.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/entities/task_list.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_step.dart';
import '../../domain/entities/todo_task.dart';
import '../../domain/repositories/task_repository.dart';

final uuidProvider = Provider<Uuid>((ref) => const Uuid());

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>(
  (ref) => TaskLocalDataSource(),
);

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>(
  (ref) => TaskRemoteDataSource(ref.watch(firestoreProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(
    remote: ref.watch(taskRemoteDataSourceProvider),
    local: ref.watch(taskLocalDataSourceProvider),
    notifications: ref.watch(notificationServiceProvider),
  );
});

final tasksProvider = StreamProvider<List<TodoTask>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <TodoTask>[]);
  return ref.watch(taskRepositoryProvider).watchTasks(user.id);
});

final listsProvider = StreamProvider<List<TaskList>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <TaskList>[]);
  return ref.watch(taskRepositoryProvider).watchLists(user.id);
});

final taskControllerProvider = Provider<TaskController>(TaskController.new);

final myDayCarryOverProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return;
  await ref
      .watch(taskRepositoryProvider)
      .carryOverExpiredMyDay(user.id, DateTimeFormatter.todayKey());
});

final deviceTokenRegistrationProvider = Provider<void>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return;

  final repository = ref.watch(taskRepositoryProvider);
  final notifications = ref.watch(notificationServiceProvider);

  unawaited(
    notifications.getFcmToken().then((token) {
      if (token != null) {
        return repository.registerDeviceToken(user.id, token);
      }
      return null;
    }).catchError((Object _) {}),
  );

  final subscription = notifications.onTokenRefresh.listen((token) {
    unawaited(
      repository.registerDeviceToken(user.id, token).catchError((Object _) {}),
    );
  });
  ref.onDispose(subscription.cancel);
});

class TaskController {
  TaskController(this._ref);

  final Ref _ref;

  Future<TodoTask> createTask({
    required String title,
    String? notes,
    String? listId,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueAt,
    DateTime? reminderAt,
    RecurrenceRule? recurrence,
    List<TaskStep> steps = const <TaskStep>[],
    bool isImportant = false,
    bool isMyDay = false,
  }) async {
    final userId = _requireUserId();
    final now = DateTime.now();
    final task = TodoTask(
      id: _ref.read(uuidProvider).v4(),
      userId: userId,
      listId: listId,
      title: title.trim(),
      notes: _clean(notes),
      priority: priority,
      dueAt: dueAt,
      reminderAt: reminderAt,
      recurrence: recurrence,
      steps: steps,
      isImportant: isImportant,
      isMyDay: isMyDay,
      myDayDate: isMyDay ? DateTimeFormatter.todayKey(now) : null,
      position: now.millisecondsSinceEpoch,
      createdAt: now,
      updatedAt: now,
    );
    await _ref.read(taskRepositoryProvider).createTask(userId, task);
    return task;
  }

  Future<void> updateTask(TodoTask task) async {
    final userId = _requireUserId();
    await _ref.read(taskRepositoryProvider).updateTask(
          userId,
          task.copyWith(updatedAt: DateTime.now()),
        );
  }

  Future<void> toggleComplete(TodoTask task) async {
    final now = DateTime.now();
    final completing = !task.isCompleted;

    if (completing && task.recurrence != null && task.dueAt != null) {
      final nextDue = task.recurrence!.nextOccurrence(task.dueAt!);
      DateTime? nextReminder;
      if (task.reminderAt != null) {
        final delta = task.reminderAt!.difference(task.dueAt!);
        nextReminder = nextDue.add(delta);
      }
      await createTask(
        title: task.title,
        notes: task.notes,
        listId: task.listId,
        priority: task.priority,
        dueAt: nextDue,
        reminderAt: nextReminder,
        recurrence: task.recurrence,
        steps: task.steps
            .map((step) => step.copyWith(isCompleted: false))
            .toList(),
        isImportant: task.isImportant,
        isMyDay: false,
      );
    }

    return updateTask(
      task.copyWith(
        isCompleted: completing,
        completedAt: completing ? now : null,
        updatedAt: now,
      ),
    );
  }

  Future<void> snoozeTask(TodoTask task, Duration duration) {
    return updateTask(
      task.copyWith(reminderAt: DateTime.now().add(duration)),
    );
  }

  Future<void> toggleImportant(TodoTask task) {
    return updateTask(task.copyWith(isImportant: !task.isImportant));
  }

  Future<void> toggleMyDay(TodoTask task) {
    final add = !task.isInMyDay(DateTimeFormatter.todayKey());
    return updateTask(
      task.copyWith(
        isMyDay: add,
        myDayDate: add ? DateTimeFormatter.todayKey() : null,
      ),
    );
  }

  Future<void> toggleStep(TodoTask task, TaskStep step) {
    final updatedSteps = task.steps.map((existing) {
      if (existing.id != step.id) return existing;
      return existing.copyWith(isCompleted: !existing.isCompleted);
    }).toList();
    return updateTask(task.copyWith(steps: updatedSteps));
  }

  Future<void> addStep(TodoTask task, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return Future.value();
    final newStep = TaskStep(
      id: _ref.read(uuidProvider).v4(),
      title: trimmed,
    );
    return updateTask(
      task.copyWith(steps: [...task.steps, newStep]),
    );
  }

  Future<void> removeStep(TodoTask task, TaskStep step) {
    return updateTask(
      task.copyWith(
        steps: task.steps.where((entry) => entry.id != step.id).toList(),
      ),
    );
  }

  Future<void> deleteTask(TodoTask task) {
    return _ref
        .read(taskRepositoryProvider)
        .deleteTask(_requireUserId(), task.id);
  }

  Future<TaskList> createList(String name, int color) async {
    final userId = _requireUserId();
    final now = DateTime.now();
    final list = TaskList(
      id: _ref.read(uuidProvider).v4(),
      userId: userId,
      name: name.trim(),
      color: color,
      position: now.millisecondsSinceEpoch,
      createdAt: now,
      updatedAt: now,
    );
    await _ref.read(taskRepositoryProvider).createList(userId, list);
    return list;
  }

  Future<void> updateList(TaskList list) {
    return _ref.read(taskRepositoryProvider).updateList(
          _requireUserId(),
          list.copyWith(updatedAt: DateTime.now()),
        );
  }

  Future<void> changeListSort(
    TaskList list, {
    required ListSortOption option,
    required bool ascending,
  }) {
    return updateList(
      list.copyWith(sortOption: option, sortAscending: ascending),
    );
  }

  Future<void> reorderLists(List<TaskList> orderedLists) async {
    final now = DateTime.now();
    for (var i = 0; i < orderedLists.length; i++) {
      final list = orderedLists[i];
      if (list.position == i) continue;
      await updateList(list.copyWith(position: i, updatedAt: now));
    }
  }

  Future<void> reorderTasks(List<TodoTask> orderedTasks) async {
    final now = DateTime.now();
    for (var i = 0; i < orderedTasks.length; i++) {
      final task = orderedTasks[i];
      if (task.position == i) continue;
      await updateTask(task.copyWith(position: i, updatedAt: now));
    }
  }

  Future<void> bulkComplete(List<TodoTask> tasks,
      {required bool completed}) async {
    final now = DateTime.now();
    for (final task in tasks) {
      if (task.isCompleted == completed) continue;
      await updateTask(
        task.copyWith(
          isCompleted: completed,
          completedAt: completed ? now : null,
        ),
      );
    }
  }

  Future<void> bulkImportant(List<TodoTask> tasks,
      {required bool important}) async {
    for (final task in tasks) {
      if (task.isImportant == important) continue;
      await updateTask(task.copyWith(isImportant: important));
    }
  }

  Future<void> bulkMyDay(List<TodoTask> tasks,
      {required bool addToMyDay}) async {
    for (final task in tasks) {
      final inMyDay = task.isInMyDay(DateTimeFormatter.todayKey());
      if (inMyDay == addToMyDay) continue;
      await updateTask(
        task.copyWith(
          isMyDay: addToMyDay,
          myDayDate: addToMyDay ? DateTimeFormatter.todayKey() : null,
        ),
      );
    }
  }

  Future<void> bulkMoveToList(List<TodoTask> tasks, String? listId) async {
    for (final task in tasks) {
      if (task.listId == listId) continue;
      await updateTask(task.copyWith(listId: listId));
    }
  }

  Future<void> bulkDelete(List<TodoTask> tasks) async {
    for (final task in tasks) {
      await deleteTask(task);
    }
  }

  Future<void> updateProfile({String? displayName}) async {
    // Profile editing handled by AuthRepository elsewhere if needed.
  }

  Future<void> deleteList(TaskList list) {
    return _ref
        .read(taskRepositoryProvider)
        .deleteList(_requireUserId(), list.id);
  }

  String _requireUserId() {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw StateError('A signed in user is required.');
    }
    return user.id;
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
