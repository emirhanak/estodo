import 'dart:async';

import 'package:flutter/foundation.dart';

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
  Future<void> _writes = Future<void>.value();

  // Reconciliation and local writes must not interleave across Hive awaits.
  Future<void> _serialized(Future<void> Function() write) {
    final result = _writes.then((_) => write());
    _writes = result.catchError((Object _) {});
    return result;
  }

  // ── Reconciliation ────────────────────────────────────────────────────────

  Future<void> _cacheRemoteTasks(String userId, List<TodoTask> tasks) {
    return _serialized(() async {
      final merged = {for (final task in tasks) task.id: task};
      for (final pending in await _local.getPendingTasks(userId)) {
        final remote = merged[pending.id];
        if (remote != null && !remote.updatedAt.isBefore(pending.updatedAt)) {
          await _local.acknowledgeTask(userId, pending.id);
        } else {
          merged[pending.id] = pending;
        }
      }
      for (final id in _local.getPendingDeletes(userId)) {
        if (merged.remove(id) == null) await _local.acknowledgeTask(userId, id);
      }
      await _local.replaceTasks(userId, merged.values.toList());
    });
  }

  Future<void> _cacheRemoteLists(String userId, List<TaskList> lists) {
    return _serialized(() async {
      final merged = {for (final list in lists) list.id: list};
      for (final pending in await _local.getPendingLists(userId)) {
        final remote = merged[pending.id];
        if (remote != null && !remote.updatedAt.isBefore(pending.updatedAt)) {
          await _local.acknowledgeList(userId, pending.id);
        } else {
          merged[pending.id] = pending;
        }
      }
      for (final id in _local.getPendingListDeletes(userId)) {
        if (merged.remove(id) == null) await _local.acknowledgeList(userId, id);
      }
      await _local.replaceLists(userId, merged.values.toList());
    });
  }

  // ── Uploads ───────────────────────────────────────────────────────────────

  Future<void> _uploadTask(String userId, TodoTask task) async {
    try {
      await _remote.upsertTask(userId, task);
    } catch (error) {
      // Permission errors are not retried by Firestore's offline queue.
      // Keep the durable local entry for the next subscription/retry.
      debugPrint('Task sync failed: $error');
    }
  }

  Future<void> _uploadList(String userId, TaskList list) async {
    try {
      await _remote.upsertList(userId, list);
    } catch (error) {
      debugPrint('List sync failed: $error');
    }
  }

  void _uploadTasksInBackground(String userId, Iterable<TodoTask> tasks) {
    for (final task in tasks) {
      unawaited(_uploadTask(userId, task));
    }
  }

  Future<void> _retryPendingTasks(String userId) async {
    _uploadTasksInBackground(userId, await _local.getPendingTasks(userId));
    for (final id in _local.getPendingDeletes(userId)) {
      _runInBackground(_remote.deleteTask(userId, id));
    }
  }

  Future<void> _retryPendingLists(String userId) async {
    for (final list in await _local.getPendingLists(userId)) {
      unawaited(_uploadList(userId, list));
    }
    for (final id in _local.getPendingListDeletes(userId)) {
      _runInBackground(_remote.deleteList(userId, id));
    }
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Streams the local cache while folding server snapshots into it.
  Stream<List<T>> _watchSynced<T>({
    required Stream<List<T>> local,
    required Stream<List<T>> remote,
    required Future<void> Function(List<T> items) cache,
    required Future<void> Function() retryPending,
    required String label,
  }) {
    late final StreamController<List<T>> controller;
    StreamSubscription<List<T>>? localSub;
    StreamSubscription<List<T>>? remoteSub;

    controller = StreamController<List<T>>.broadcast(
      onListen: () {
        localSub = local.listen(controller.add, onError: controller.addError);
        // Remote errors must not break the local stream; the cache keeps
        // serving data and pending changes are retried on next subscription.
        remoteSub = remote.listen(
          (items) => _runInBackground(cache(items)),
          onError: (Object error) => debugPrint('$label stream failed: $error'),
        );
        _runInBackground(retryPending());
      },
      onCancel: () {
        localSub?.cancel();
        remoteSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Stream<List<TodoTask>> watchTasks(String userId) => _watchSynced(
        local: _local.watchTasks(userId),
        remote: _remote.watchTasks(userId),
        cache: (tasks) => _cacheRemoteTasks(userId, tasks),
        retryPending: () => _retryPendingTasks(userId),
        label: 'Task',
      );

  @override
  Stream<List<TaskList>> watchLists(String userId) => _watchSynced(
        local: _local.watchLists(userId),
        remote: _remote.watchLists(userId),
        cache: (lists) => _cacheRemoteLists(userId, lists),
        retryPending: () => _retryPendingLists(userId),
        label: 'List',
      );

  // ── Tasks ─────────────────────────────────────────────────────────────────

  @override
  Future<void> createTask(String userId, TodoTask task) =>
      _saveTask(userId, task);

  @override
  Future<void> updateTask(String userId, TodoTask task) =>
      _saveTask(userId, task);

  Future<void> _saveTask(String userId, TodoTask task) async {
    await _serialized(() => _local.upsertTask(userId, task, pending: true));
    unawaited(_uploadTask(userId, task));
    _syncReminderInBackground(task);
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    await _serialized(() => _local.deleteTask(userId, taskId, pending: true));
    _runInBackground(_remote.deleteTask(userId, taskId));
    _runInBackground(_notifications.cancelTaskReminder(taskId));
  }

  /// Applies [change] to matching local tasks as pending edits and uploads
  /// them in the background, so callers never wait on the network.
  Future<void> _editTasksLocally(
    String userId,
    bool Function(TodoTask task) where,
    TodoTask Function(TodoTask task, DateTime now) change, {
    Future<void> Function()? alsoLocally,
  }) async {
    final edited = <TodoTask>[];
    await _serialized(() async {
      final now = DateTime.now();
      for (final task in (await _local.getTasks(userId)).where(where)) {
        final updated = change(task, now);
        await _local.upsertTask(userId, updated, pending: true);
        edited.add(updated);
      }
      await alsoLocally?.call();
    });
    _uploadTasksInBackground(userId, edited);
  }

  @override
  Future<void> carryOverExpiredMyDay(String userId, String todayKey) {
    return _editTasksLocally(
      userId,
      (task) => task.isMyDay && task.myDayDate != todayKey && !task.isCompleted,
      (task, now) => task.copyWith(myDayDate: todayKey, updatedAt: now),
    );
  }

  // ── Lists ─────────────────────────────────────────────────────────────────

  @override
  Future<void> createList(String userId, TaskList list) =>
      _saveList(userId, list);

  @override
  Future<void> updateList(String userId, TaskList list) =>
      _saveList(userId, list);

  Future<void> _saveList(String userId, TaskList list) async {
    await _serialized(() => _local.upsertList(userId, list, pending: true));
    unawaited(_uploadList(userId, list));
  }

  @override
  Future<void> deleteList(String userId, String listId) async {
    await _editTasksLocally(
      userId,
      (task) => task.listId == listId,
      (task, now) => task.copyWith(listId: null, updatedAt: now),
      alsoLocally: () => _local.deleteList(userId, listId, pending: true),
    );
    _runInBackground(_remote.deleteList(userId, listId));
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
