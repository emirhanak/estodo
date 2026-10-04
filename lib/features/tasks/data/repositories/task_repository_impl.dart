import 'dart:async';

import '../../../../core/services/notification_service.dart';
import '../../domain/entities/task_list.dart';
import '../../domain/entities/todo_task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/task_remote_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required TaskRemoteDataSource remote,
    required TaskLocalDataSource local,
    required NotificationService notifications,
  })  : _remote = remote,
        _local = local,
        _notifications = notifications;

  final TaskRemoteDataSource _remote;
  final TaskLocalDataSource _local;
  final NotificationService _notifications;
  final _pendingTasks = <String, TodoTask>{};
  final _pendingDeletes = <String>{};
  Future<void> _taskWrites = Future<void>.value();

  // Reconciliation and local writes must not interleave across Hive awaits.
  Future<void> _writeTasks(Future<void> Function() write) {
    final result = _taskWrites.then((_) => write());
    _taskWrites = result.catchError((Object _) {});
    return result;
  }

  Future<void> _cacheRemoteTasks(String userId, List<TodoTask> tasks) {
    return _writeTasks(() async {
      final merged = {for (final task in tasks) task.id: task};
      final prefix = '$userId:';
      for (final key in _pendingTasks.keys.toList()) {
        if (!key.startsWith(prefix)) continue;
        final pending = _pendingTasks[key]!;
        final remote = merged[pending.id];
        if (remote != null && !remote.updatedAt.isBefore(pending.updatedAt)) {
          _pendingTasks.remove(key);
        } else {
          merged[pending.id] = pending;
        }
      }
      for (final key in _pendingDeletes.toList()) {
        if (!key.startsWith(prefix)) continue;
        final id = key.substring(prefix.length);
        if (merged.remove(id) == null) _pendingDeletes.remove(key);
      }
      await _local.replaceTasks(userId, merged.values.toList());
    });
  }

  Future<void> _saveLocalTask(String userId, TodoTask task) {
    return _writeTasks(() async {
      await _local.upsertTask(userId, task);
      final key = '$userId:${task.id}';
      _pendingTasks[key] = task;
      _pendingDeletes.remove(key);
    });
  }

  @override
  Stream<List<TodoTask>> watchTasks(String userId) {
    late final StreamController<List<TodoTask>> controller;
    StreamSubscription<List<TodoTask>>? localSub;
    StreamSubscription<List<TodoTask>>? remoteSub;

    controller = StreamController<List<TodoTask>>.broadcast(
      onListen: () {
        localSub = _local.watchTasks(userId).listen(
              controller.add,
              onError: controller.addError,
            );
        remoteSub = _remote.watchTasks(userId).listen(
          (tasks) => _runInBackground(_cacheRemoteTasks(userId, tasks)),
          onError: (Object error) {
            // Keep streaming from local storage even if remote encounters errors
          },
        );
      },
      onCancel: () {
        localSub?.cancel();
        remoteSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Stream<List<TaskList>> watchLists(String userId) {
    late final StreamController<List<TaskList>> controller;
    StreamSubscription<List<TaskList>>? localSub;
    StreamSubscription<List<TaskList>>? remoteSub;

    controller = StreamController<List<TaskList>>.broadcast(
      onListen: () {
        localSub = _local.watchLists(userId).listen(
              controller.add,
              onError: controller.addError,
            );
        remoteSub = _remote.watchLists(userId).listen(
          (lists) async {
            await _local.replaceLists(userId, lists);
          },
          onError: (Object error) {},
        );
      },
      onCancel: () {
        localSub?.cancel();
        remoteSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> createTask(String userId, TodoTask task) async {
    await _saveLocalTask(userId, task);
    unawaited(_remote.upsertTask(userId, task).catchError((Object error) {
      // Remote sync failure handled gracefully by offline Firestore queue
    }));
    _syncReminderInBackground(task);
  }

  @override
  Future<void> updateTask(String userId, TodoTask task) async {
    await _saveLocalTask(userId, task);
    unawaited(_remote.upsertTask(userId, task).catchError((Object error) {
      // Remote sync failure handled gracefully by offline Firestore queue
    }));
    _syncReminderInBackground(task);
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    await _writeTasks(() async {
      await _local.deleteTask(userId, taskId);
      final key = '$userId:$taskId';
      _pendingTasks.remove(key);
      _pendingDeletes.add(key);
    });
    unawaited(_remote.deleteTask(userId, taskId).catchError((Object error) {}));
    _runInBackground(_notifications.cancelTaskReminder(taskId));
  }

  @override
  Future<void> createList(String userId, TaskList list) async {
    await _local.upsertList(userId, list);
    unawaited(_remote.upsertList(userId, list).catchError((Object error) {}));
  }

  @override
  Future<void> updateList(String userId, TaskList list) async {
    await _local.upsertList(userId, list);
    unawaited(_remote.upsertList(userId, list).catchError((Object error) {}));
  }

  @override
  Future<void> deleteList(String userId, String listId) async {
    final tasks = await _local.getTasks(userId);
    for (final task in tasks.where((task) => task.listId == listId)) {
      await _local.upsertTask(
        userId,
        task.copyWith(listId: null, updatedAt: DateTime.now()),
      );
    }
    await _local.deleteList(userId, listId);
    await _remote.deleteList(userId, listId);
  }

  @override
  Future<void> carryOverExpiredMyDay(String userId, String todayKey) async {
    final tasks = await _local.getTasks(userId);
    for (final task in tasks.where(
      (task) => task.isMyDay && task.myDayDate != todayKey && !task.isCompleted,
    )) {
      await _local.upsertTask(
        userId,
        task.copyWith(
          isMyDay: true,
          myDayDate: todayKey,
          updatedAt: DateTime.now(),
        ),
      );
    }
    await _remote.carryOverExpiredMyDay(userId, todayKey);
  }

  @override
  Future<void> registerDeviceToken(String userId, String token) {
    return _remote.registerDeviceToken(userId, token);
  }

  /// Reminder scheduling can block on a permission prompt; saving must not.
  void _syncReminderInBackground(TodoTask task) =>
      _runInBackground(_syncReminder(task));

  void _runInBackground(Future<void> work) {
    unawaited(work.catchError((Object error) {}));
  }

  Future<void> _syncReminder(TodoTask task) async {
    if (task.isCompleted || task.reminderAt == null) {
      await _notifications.cancelTaskReminder(task.id);
      return;
    }
    await _notifications.scheduleTaskReminder(
      taskId: task.id,
      title: task.title,
      body: task.notes,
      reminderAt: task.reminderAt!,
    );
  }
}
