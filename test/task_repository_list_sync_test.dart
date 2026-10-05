import 'dart:async';
import 'dart:io';

import 'package:estodo/core/services/notification_service.dart';
import 'package:estodo/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:estodo/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:estodo/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:estodo/features/tasks/domain/entities/task_list.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// A backend that never answers, like Firestore while the device is offline.
class _OfflineRemote implements TaskRemoteDataSource {
  final taskSnapshots = StreamController<List<TodoTask>>.broadcast();
  final listSnapshots = StreamController<List<TaskList>>.broadcast();
  final listWrite = Completer<void>();
  final deletedLists = <String>[];
  final uploadedTasks = <TodoTask>[];

  @override
  Stream<List<TodoTask>> watchTasks(String userId) => taskSnapshots.stream;

  @override
  Stream<List<TaskList>> watchLists(String userId) => listSnapshots.stream;

  @override
  Future<void> upsertTask(String userId, TodoTask task) {
    uploadedTasks.add(task);
    return Completer<void>().future;
  }

  @override
  Future<void> deleteTask(String userId, String taskId) =>
      Completer<void>().future;

  @override
  Future<void> upsertList(String userId, TaskList list) => listWrite.future;

  @override
  Future<void> deleteList(String userId, String listId) {
    deletedLists.add(listId);
    return Completer<void>().future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifications implements NotificationService {
  @override
  Future<void> cancelTaskReminder(String taskId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _waitFor(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

final _date = DateTime(2026, 10, 4, 9);

TaskList _list(String id) => TaskList(
      id: id,
      userId: 'u',
      name: 'List $id',
      color: 0xFF0078D4,
      createdAt: _date,
      updatedAt: _date,
    );

TodoTask _task(String id, {String? listId, bool isMyDay = false}) => TodoTask(
      id: id,
      userId: 'u',
      title: 'Task $id',
      listId: listId,
      isMyDay: isMyDay,
      myDayDate: isMyDay ? '2026-10-03' : null,
      createdAt: _date,
      updatedAt: _date,
    );

void main() {
  late Directory directory;
  late TaskLocalDataSource local;
  late _OfflineRemote remote;
  late TaskRepositoryImpl repository;

  Future<void> reopen() async {
    await Hive.close();
    local = TaskLocalDataSource(
      taskBox: await Hive.openBox('tasks'),
      listBox: await Hive.openBox('lists'),
    );
    repository = TaskRepositoryImpl(
      remote: remote,
      local: local,
      notifications: _Notifications(),
    );
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('estodo-lists-');
    Hive.init(directory.path);
    remote = _OfflineRemote();
    await reopen();
  });

  tearDown(() async {
    if (!remote.listWrite.isCompleted) remote.listWrite.complete();
    await remote.taskSnapshots.close();
    await remote.listSnapshots.close();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('deleting a list offline completes and re-homes its tasks', () async {
    await local.upsertList('u', _list('l1'));
    await local.upsertTask('u', _task('t1', listId: 'l1'));
    await local.upsertTask('u', _task('t2'));

    await repository.deleteList('u', 'l1').timeout(const Duration(seconds: 1));

    expect(await local.getLists('u'), isEmpty);
    expect(local.getPendingListDeletes('u'), ['l1']);
    final moved = (await local.getTasks('u')).firstWhere((t) => t.id == 't1');
    expect(moved.listId, isNull);
    expect(moved.updatedAt.isAfter(_date), isTrue);
    expect((await local.getPendingTasks('u')).map((t) => t.id), ['t1']);
    await _waitFor(() => remote.deletedLists.contains('l1'));
    expect(remote.uploadedTasks.map((t) => t.id), ['t1']);
  });

  test('carrying over My Day offline completes and marks tasks pending',
      () async {
    await local.upsertTask('u', _task('old', isMyDay: true));

    await repository
        .carryOverExpiredMyDay('u', '2026-10-04')
        .timeout(const Duration(seconds: 1));

    final task = (await local.getTasks('u')).single;
    expect(task.myDayDate, '2026-10-04');
    expect((await local.getPendingTasks('u')).single.id, 'old');
    await _waitFor(() => remote.uploadedTasks.any((t) => t.id == 'old'));
  });

  test('rejected list write survives Hive reopen and empty server result',
      () async {
    await repository.createList('u', _list('new'));
    remote.listWrite.completeError(StateError('permission-denied'));
    await Future<void>.delayed(Duration.zero);
    await reopen();

    final emissions = <List<TaskList>>[];
    final subscription = repository.watchLists('u').listen(emissions.add);
    addTearDown(subscription.cancel);
    await _waitFor(() => emissions.isNotEmpty);
    expect(emissions.last.single.id, 'new');

    final before = emissions.length;
    remote.listSnapshots.add([]);
    await _waitFor(() => emissions.length > before);
    expect(emissions.last.single.id, 'new');
    expect((await local.getPendingLists('u')).single.id, 'new');

    // The server echo acknowledges the write.
    remote.listSnapshots.add([_list('new')]);
    await _waitFor(() => local.getPendingListIds('u').isEmpty);
    expect((await local.getLists('u')).single.id, 'new');
  });

  test('pending list deletion survives a stale server result', () async {
    await local.upsertList('u', _list('gone'));
    await repository.deleteList('u', 'gone');
    await reopen();

    final emissions = <List<TaskList>>[];
    final subscription = repository.watchLists('u').listen(emissions.add);
    addTearDown(subscription.cancel);
    await _waitFor(() => emissions.isNotEmpty);

    remote.listSnapshots.add([_list('gone'), _list('other')]);
    await _waitFor(() => emissions.last.any((l) => l.id == 'other'));
    expect((await local.getLists('u')).map((l) => l.id), ['other']);
    expect(local.getPendingListDeletes('u'), ['gone']);

    remote.listSnapshots.add([_list('other')]);
    await _waitFor(() => local.getPendingListDeletes('u').isEmpty);
  });
}
