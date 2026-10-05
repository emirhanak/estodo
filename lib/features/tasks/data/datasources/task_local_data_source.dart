import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/task_list.dart';
import '../../domain/entities/todo_task.dart';
import '../models/task_dto.dart';
import '../models/task_list_dto.dart';

/// Hive cache for tasks and lists.
///
/// Records written locally carry `_pendingSync` until the server confirms them;
/// local deletions leave a `_pendingDelete` tombstone until the server drops
/// the document. Both markers survive app restarts.
class TaskLocalDataSource {
  TaskLocalDataSource({
    Box? taskBox,
    Box? listBox,
  })  : _taskBox = taskBox ?? Hive.box(AppConstants.tasksBox),
        _listBox = listBox ?? Hive.box(AppConstants.listsBox);

  static const _pendingSync = '_pendingSync';
  static const _pendingDelete = '_pendingDelete';

  final Box _taskBox;
  final Box _listBox;

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Stream<List<TodoTask>> watchTasks(String userId) =>
      _watch(_taskBox, () => getTasks(userId));

  Future<List<TodoTask>> getTasks(String userId) async {
    final tasks = _read(_taskBox, userId, TaskDto.fromLocal);
    tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return tasks;
  }

  Future<void> upsertTask(String userId, TodoTask task, {bool? pending}) =>
      _upsert(_taskBox, userId, task.id, TaskDto.toLocal(task), pending);

  Future<List<TodoTask>> getPendingTasks(String userId) async =>
      _read(_taskBox, userId, TaskDto.fromLocal, onlyPending: true);

  List<String> getPendingDeletes(String userId) =>
      _tombstones(_taskBox, userId);

  Future<void> acknowledgeTask(String userId, String taskId) =>
      _acknowledge(_taskBox, userId, taskId);

  Future<void> deleteTask(String userId, String taskId,
          {bool pending = false}) =>
      _delete(_taskBox, userId, taskId, pending);

  Future<void> replaceTasks(String userId, List<TodoTask> tasks) => _replace(
        _taskBox,
        userId,
        {for (final task in tasks) task.id: TaskDto.toLocal(task)},
      );

  // ── Lists ─────────────────────────────────────────────────────────────────

  Stream<List<TaskList>> watchLists(String userId) =>
      _watch(_listBox, () => getLists(userId));

  Future<List<TaskList>> getLists(String userId) async {
    final lists = _read(_listBox, userId, TaskListDto.fromLocal);
    lists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return lists;
  }

  Future<void> upsertList(String userId, TaskList list, {bool? pending}) =>
      _upsert(_listBox, userId, list.id, TaskListDto.toLocal(list), pending);

  Future<List<TaskList>> getPendingLists(String userId) async =>
      _read(_listBox, userId, TaskListDto.fromLocal, onlyPending: true);

  List<String> getPendingListIds(String userId) => _listBox.keys
      .where((key) =>
          _ownsKey(userId, key) && _flag(_listBox.get(key), _pendingSync))
      .map<String>((key) => _idFromKey(key as Object))
      .toList();

  List<String> getPendingListDeletes(String userId) =>
      _tombstones(_listBox, userId);

  Future<void> acknowledgeList(String userId, String listId) =>
      _acknowledge(_listBox, userId, listId);

  Future<void> deleteList(String userId, String listId,
          {bool pending = false}) =>
      _delete(_listBox, userId, listId, pending);

  Future<void> replaceLists(String userId, List<TaskList> lists) => _replace(
        _listBox,
        userId,
        {for (final list in lists) list.id: TaskListDto.toLocal(list)},
      );

  // ── Shared box helpers ────────────────────────────────────────────────────

  Stream<List<T>> _watch<T>(Box box, Future<List<T>> Function() read) async* {
    // Listen before the initial read so a save during startup is not missed.
    final changes = StreamController<void>();
    final subscription = box.watch().listen((_) => changes.add(null));
    try {
      yield await read();
      yield* changes.stream.asyncMap((_) => read());
    } finally {
      await subscription.cancel();
      unawaited(changes.close());
    }
  }

  List<T> _read<T>(
    Box box,
    String userId,
    T Function(String id, Map<dynamic, dynamic> data) decode, {
    bool onlyPending = false,
  }) {
    final items = <T>[];
    for (final key in box.keys.where((key) => _ownsKey(userId, key))) {
      final value = box.get(key);
      if (value is! Map || value[_pendingDelete] == true) continue;
      if (onlyPending && value[_pendingSync] != true) continue;
      items.add(decode(_idFromKey(key), value));
    }
    return items;
  }

  Future<void> _upsert(
    Box box,
    String userId,
    String id,
    Map<String, dynamic> data,
    bool? pending,
  ) {
    final key = _key(userId, id);
    final keepPending = pending ?? _flag(box.get(key), _pendingSync);
    return box.put(key, {...data, if (keepPending) _pendingSync: true});
  }

  List<String> _tombstones(Box box, String userId) => box.keys
      .where(
          (key) => _ownsKey(userId, key) && _flag(box.get(key), _pendingDelete))
      .map<String>((key) => _idFromKey(key as Object))
      .toList();

  Future<void> _acknowledge(Box box, String userId, String id) async {
    final key = _key(userId, id);
    final value = box.get(key);
    if (value is! Map) return;
    if (value[_pendingDelete] == true) {
      await box.delete(key);
    } else {
      await box.put(key, Map.of(value)..remove(_pendingSync));
    }
  }

  Future<void> _delete(Box box, String userId, String id, bool pending) {
    final key = _key(userId, id);
    return pending ? box.put(key, {_pendingDelete: true}) : box.delete(key);
  }

  /// Replaces the user's cached records with [incoming], keeping pending
  /// markers and tombstones so unconfirmed local changes are not lost.
  Future<void> _replace(
    Box box,
    String userId,
    Map<String, Map<String, dynamic>> incoming,
  ) async {
    final incomingKeys = {for (final id in incoming.keys) _key(userId, id)};
    final staleKeys = box.keys
        .where((key) =>
            _ownsKey(userId, key) &&
            !incomingKeys.contains(key) &&
            !_flag(box.get(key), _pendingDelete))
        .toList();
    await box.putAll({
      for (final entry in incoming.entries)
        _key(userId, entry.key): {
          ...entry.value,
          if (_flag(box.get(_key(userId, entry.key)), _pendingSync))
            _pendingSync: true,
        },
    });
    await box.deleteAll(staleKeys);
  }

  bool _flag(Object? value, String flag) => value is Map && value[flag] == true;

  String _key(String userId, String id) => '$userId:$id';

  bool _ownsKey(String userId, Object? key) =>
      key.toString().startsWith('$userId:');

  String _idFromKey(Object key) => key.toString().split(':').last;
}
