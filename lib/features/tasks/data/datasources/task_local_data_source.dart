import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/task_list.dart';
import '../../domain/entities/todo_task.dart';
import '../models/task_dto.dart';
import '../models/task_list_dto.dart';

class TaskLocalDataSource {
  TaskLocalDataSource({
    Box? taskBox,
    Box? listBox,
  })  : _taskBox = taskBox ?? Hive.box(AppConstants.tasksBox),
        _listBox = listBox ?? Hive.box(AppConstants.listsBox);

  final Box _taskBox;
  final Box _listBox;

  Stream<List<TodoTask>> watchTasks(String userId) async* {
    // Listen before the initial read so a save during startup is not missed.
    final changes = StreamController<void>();
    final subscription = _taskBox.watch().listen((_) => changes.add(null));
    try {
      yield await getTasks(userId);
      yield* changes.stream.asyncMap((_) => getTasks(userId));
    } finally {
      await subscription.cancel();
      unawaited(changes.close());
    }
  }

  Stream<List<TaskList>> watchLists(String userId) async* {
    yield await getLists(userId);
    yield* _listBox.watch().asyncMap((_) => getLists(userId));
  }

  Future<List<TodoTask>> getTasks(String userId) async {
    final tasks = <TodoTask>[];
    for (final key in _taskBox.keys.where((key) => _ownsKey(userId, key))) {
      final value = _taskBox.get(key);
      if (value is Map && value['_pendingDelete'] != true) {
        tasks.add(TaskDto.fromLocal(_idFromKey(key), value));
      }
    }
    tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return tasks;
  }

  Future<List<TaskList>> getLists(String userId) async {
    final lists = <TaskList>[];
    for (final key in _listBox.keys.where((key) => _ownsKey(userId, key))) {
      final value = _listBox.get(key);
      if (value is Map) {
        lists.add(TaskListDto.fromLocal(_idFromKey(key), value));
      }
    }
    lists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return lists;
  }

  Future<void> upsertTask(String userId, TodoTask task, {bool? pending}) {
    return _taskBox.put(_key(userId, task.id), {
      ...TaskDto.toLocal(task),
      if (pending == true ||
          (pending == null &&
              (_taskBox.get(_key(userId, task.id)) as Map?)?['_pendingSync'] ==
                  true))
        '_pendingSync': true,
    });
  }

  Future<List<TodoTask>> getPendingTasks(String userId) async =>
      (await getTasks(userId))
          .where((task) =>
              (_taskBox.get(_key(userId, task.id)) as Map)['_pendingSync'] ==
              true)
          .toList();

  List<String> getPendingDeletes(String userId) => _taskBox.keys
      .where((key) =>
          _ownsKey(userId, key) &&
          (_taskBox.get(key) as Map)['_pendingDelete'] == true)
      .map<String>((key) => _idFromKey(key as Object))
      .toList();

  Future<void> acknowledgeTask(String userId, String taskId) async {
    final key = _key(userId, taskId);
    final value = _taskBox.get(key);
    if (value is! Map) return;
    if (value['_pendingDelete'] == true) {
      await _taskBox.delete(key);
    } else {
      await _taskBox.put(key, Map.of(value)..remove('_pendingSync'));
    }
  }

  Future<void> upsertList(String userId, TaskList list) {
    return _listBox.put(_key(userId, list.id), TaskListDto.toLocal(list));
  }

  Future<void> deleteTask(String userId, String taskId,
      {bool pending = false}) {
    final key = _key(userId, taskId);
    return pending
        ? _taskBox.put(key, {'_pendingDelete': true})
        : _taskBox.delete(key);
  }

  Future<void> deleteList(String userId, String listId) {
    return _listBox.delete(_key(userId, listId));
  }

  Future<void> replaceTasks(String userId, List<TodoTask> tasks) async {
    final incomingKeys = {for (final task in tasks) _key(userId, task.id)};
    final staleKeys = _taskBox.keys
        .where((key) =>
            _ownsKey(userId, key) &&
            !incomingKeys.contains(key) &&
            (_taskBox.get(key) as Map)['_pendingDelete'] != true)
        .toList();
    await _taskBox.putAll({
      for (final task in tasks)
        _key(userId, task.id): {
          ...TaskDto.toLocal(task),
          if ((_taskBox.get(_key(userId, task.id)) as Map?)?['_pendingSync'] ==
              true)
            '_pendingSync': true,
        },
    });
    await _taskBox.deleteAll(staleKeys);
  }

  Future<void> replaceLists(String userId, List<TaskList> lists) async {
    final staleKeys =
        _listBox.keys.where((key) => _ownsKey(userId, key)).toList();
    await _listBox.deleteAll(staleKeys);
    await _listBox.putAll({
      for (final list in lists)
        _key(userId, list.id): TaskListDto.toLocal(list),
    });
  }

  String _key(String userId, String id) => '$userId:$id';

  bool _ownsKey(String userId, Object? key) =>
      key.toString().startsWith('$userId:');

  String _idFromKey(Object key) => key.toString().split(':').last;
}
