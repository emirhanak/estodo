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
  Stream<List<TodoTask>> watchTasks(String userId) async* {
    yield await _local.getTasks(userId);
    await for (final tasks in _remote.watchTasks(userId)) {
      await _local.replaceTasks(userId, tasks);
      yield tasks;
    }
  }

  @override
  Stream<List<TaskList>> watchLists(String userId) async* {
    yield await _local.getLists(userId);
    await for (final lists in _remote.watchLists(userId)) {
      await _local.replaceLists(userId, lists);
      yield lists;
    }
  }

  @override
  Future<void> createTask(String userId, TodoTask task) async {
    await _local.upsertTask(userId, task);
    await _remote.upsertTask(userId, task);
    await _syncReminder(task);
  }

  @override
  Future<void> updateTask(String userId, TodoTask task) async {
    await _local.upsertTask(userId, task);
    await _remote.upsertTask(userId, task);
    await _syncReminder(task);
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    await _local.deleteTask(userId, taskId);
    await _remote.deleteTask(userId, taskId);
    await _notifications.cancelTaskReminder(taskId);
  }

  @override
  Future<void> createList(String userId, TaskList list) async {
    await _local.upsertList(userId, list);
    await _remote.upsertList(userId, list);
  }

  @override
  Future<void> updateList(String userId, TaskList list) async {
    await _local.upsertList(userId, list);
    await _remote.upsertList(userId, list);
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
