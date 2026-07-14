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
    yield await getTasks(userId);
    yield* _taskBox.watch().asyncMap((_) => getTasks(userId));
  }

  Stream<List<TaskList>> watchLists(String userId) async* {
    yield await getLists(userId);
    yield* _listBox.watch().asyncMap((_) => getLists(userId));
  }

  Future<List<TodoTask>> getTasks(String userId) async {
    final tasks = <TodoTask>[];
    for (final key in _taskBox.keys.where((key) => _ownsKey(userId, key))) {
      final value = _taskBox.get(key);
      if (value is Map) {
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

  Future<void> upsertTask(String userId, TodoTask task) {
    return _taskBox.put(_key(userId, task.id), TaskDto.toLocal(task));
  }

  Future<void> upsertList(String userId, TaskList list) {
    return _listBox.put(_key(userId, list.id), TaskListDto.toLocal(list));
  }

  Future<void> deleteTask(String userId, String taskId) {
    return _taskBox.delete(_key(userId, taskId));
  }

  Future<void> deleteList(String userId, String listId) {
    return _listBox.delete(_key(userId, listId));
  }

  Future<void> replaceTasks(String userId, List<TodoTask> tasks) async {
    final staleKeys = _taskBox.keys.where((key) => _ownsKey(userId, key)).toList();
    await _taskBox.deleteAll(staleKeys);
    await _taskBox.putAll({
      for (final task in tasks) _key(userId, task.id): TaskDto.toLocal(task),
    });
  }

  Future<void> replaceLists(String userId, List<TaskList> lists) async {
    final staleKeys = _listBox.keys.where((key) => _ownsKey(userId, key)).toList();
    await _listBox.deleteAll(staleKeys);
    await _listBox.putAll({
      for (final list in lists) _key(userId, list.id): TaskListDto.toLocal(list),
    });
  }

  String _key(String userId, String id) => '$userId:$id';

  bool _ownsKey(String userId, Object? key) => key.toString().startsWith('$userId:');

  String _idFromKey(Object key) => key.toString().split(':').last;
}
