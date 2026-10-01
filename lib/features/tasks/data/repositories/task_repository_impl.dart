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
          (tasks) async {
            await _local.replaceTasks(userId, tasks);
          },
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
    await _local.upsertTask(userId, task);
    unawaited(_remote.upsertTask(userId, task).catchError((Object error) {
      // Remote sync failure handled gracefully by offline Firestore queue
    }));
    _syncReminderInBackground(task);
  }

  @override
  Future<void> updateTask(String userId, TodoTask task) async {
    await _local.upsertTask(userId, task);
    unawaited(_remote.upsertTask(userId, task).catchError((Object error) {
      // Remote sync failure handled gracefully by offline Firestore queue
    }));
    _syncReminderInBackground(task);
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    await _local.deleteTask(userId, taskId);
    unawaited(_remote.deleteTask(userId, taskId).catchError((Object error) {}));
    await _notifications.cancelTaskReminder(taskId);
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
  void _syncReminderInBackground(TodoTask task) {
    unawaited(_syncReminder(task).catchError((Object error) {}));
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
