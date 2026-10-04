import 'dart:async';
import 'dart:io';

import 'package:estodo/core/services/notification_service.dart';
import 'package:estodo/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:estodo/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:estodo/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _Remote implements TaskRemoteDataSource {
  final snapshots = StreamController<List<TodoTask>>.broadcast();
  final pendingWrite = Completer<void>();

  @override
  Stream<List<TodoTask>> watchTasks(String userId) => snapshots.stream;

  @override
  Future<void> upsertTask(String userId, TodoTask task) => pendingWrite.future;

  @override
  Future<void> deleteTask(String userId, String taskId) => pendingWrite.future;

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
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for the Hive stream to finish its write');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Directory directory;
  late TaskLocalDataSource local;
  late _Remote remote;
  late TaskRepositoryImpl repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('estodo-sync-');
    Hive.init(directory.path);
    local = TaskLocalDataSource(
      taskBox: await Hive.openBox('tasks'),
      listBox: await Hive.openBox('lists'),
    );
    remote = _Remote();
    repository = TaskRepositoryImpl(
      remote: remote,
      local: local,
      notifications: _Notifications(),
    );
  });

  tearDown(() async {
    if (!remote.pendingWrite.isCompleted) remote.pendingWrite.complete();
    await remote.snapshots.close();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  for (final habit in [false, true]) {
    test(
        'stale remote snapshot keeps newly created planned entry (habit=$habit)',
        () async {
      final emissions = <List<TodoTask>>[];
      final subscription = repository.watchTasks('u').listen(emissions.add);
      addTearDown(subscription.cancel);
      await _waitFor(() => emissions.isNotEmpty);
      final date = DateTime(2026, 10, 4, 9);
      final task = TodoTask(
        id: 'new',
        userId: 'u',
        title: 'Plan',
        isHabit: habit,
        dueAt: date,
        startAt: date,
        durationMinutes: 30,
        createdAt: date,
        updatedAt: date,
      );
      await repository.createTask('u', task);
      await _waitFor(() => emissions.last.isNotEmpty);
      expect(emissions.last.single.id, task.id);
      final afterSave = emissions.length;
      remote.snapshots.add([]);
      await _waitFor(() => emissions.length > afterSave);
      final saved = (await local.getTasks('u')).single;
      expect(saved.id, task.id);
      expect(saved.dueAt, task.dueAt);
      expect(saved.isHabit, habit);
      expect(emissions.skip(afterSave).every((tasks) => tasks.length == 1),
          isTrue);

      // An echo acknowledges the write; later server deletion is authoritative.
      final beforeEcho = emissions.length;
      remote.snapshots.add([task]);
      await _waitFor(() => emissions.length > beforeEcho);
      remote.snapshots.add([]);
      await _waitFor(() => emissions.last.isEmpty);
      expect(await local.getTasks('u'), isEmpty);
    });
  }

  test('older remote version cannot undo a local edit or deletion', () async {
    final date = DateTime(2026, 10, 4, 9);
    final original = TodoTask(
      id: 'edit',
      userId: 'u',
      title: 'Before',
      dueAt: date,
      createdAt: date,
      updatedAt: date,
    );
    final emissions = <List<TodoTask>>[];
    final subscription = repository.watchTasks('u').listen(emissions.add);
    addTearDown(subscription.cancel);
    await _waitFor(() => emissions.isNotEmpty);
    remote.snapshots.add([original]);
    await _waitFor(() => emissions.last.isNotEmpty);
    final edited = original.copyWith(
      title: 'After',
      updatedAt: date.add(const Duration(minutes: 1)),
    );
    await repository.updateTask('u', edited);
    await _waitFor(() => emissions.last.single.title == 'After');
    final beforeStale = emissions.length;
    remote.snapshots.add([original]);
    await _waitFor(() => emissions.length > beforeStale);
    expect((await local.getTasks('u')).single.title, 'After');
    await repository.deleteTask('u', original.id);
    await _waitFor(() => emissions.last.isEmpty);
    remote.snapshots.add([original, original.copyWith(id: 'other')]);
    await _waitFor(() => emissions.last.any((task) => task.id == 'other'));
    expect((await local.getTasks('u')).map((task) => task.id), ['other']);
  });

  test('rejected planned write survives Hive reopen and empty server result',
      () async {
    final date = DateTime(2026, 10, 4);
    final task = TodoTask(
        id: 'rejected',
        userId: 'u',
        title: 'Persisted',
        dueAt: date,
        createdAt: date,
        updatedAt: date);
    await repository.createTask('u', task);
    remote.pendingWrite.completeError(StateError('permission-denied'));
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    local = TaskLocalDataSource(
        taskBox: await Hive.openBox('tasks'),
        listBox: await Hive.openBox('lists'));
    repository = TaskRepositoryImpl(
        remote: remote, local: local, notifications: _Notifications());
    final emissions = <List<TodoTask>>[];
    final subscription = repository.watchTasks('u').listen(emissions.add);
    addTearDown(subscription.cancel);
    await _waitFor(() => emissions.isNotEmpty);
    expect(emissions.last.single.id, task.id);
    final before = emissions.length;
    remote.snapshots.add([]);
    await _waitFor(() => emissions.length > before);
    expect(emissions.last.single.id, task.id);
    expect((await local.getPendingTasks('u')).single.id, task.id);
    remote.snapshots.add([task]);
    await _waitFor(() => emissions.length > before + 1);
    expect(await local.getPendingTasks('u'), isEmpty);
  });

  test('pending deletion survives Hive reopen and a stale server result',
      () async {
    final date = DateTime(2026, 10, 4);
    final task = TodoTask(
        id: 'deleted',
        userId: 'u',
        title: 'Deleted',
        dueAt: date,
        createdAt: date,
        updatedAt: date);
    await local.upsertTask('u', task);
    await repository.deleteTask('u', task.id);
    await Hive.close();
    local = TaskLocalDataSource(
        taskBox: await Hive.openBox('tasks'),
        listBox: await Hive.openBox('lists'));
    repository = TaskRepositoryImpl(
        remote: remote, local: local, notifications: _Notifications());
    final emissions = <List<TodoTask>>[];
    final subscription = repository.watchTasks('u').listen(emissions.add);
    addTearDown(subscription.cancel);
    await _waitFor(() => emissions.isNotEmpty);
    remote.snapshots.add([task]);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(await local.getTasks('u'), isEmpty);
    expect(local.getPendingDeletes('u'), [task.id]);
    remote.snapshots.add([]);
    await _waitFor(() => local.getPendingDeletes('u').isEmpty);
  });

  test('save during initial stream delivery is observed', () async {
    final date = DateTime(2026, 10, 4);
    final task = TodoTask(
      id: 'startup',
      userId: 'u',
      title: 'Startup',
      dueAt: date,
      createdAt: date,
      updatedAt: date,
    );
    final observed = Completer<List<TodoTask>>();
    final subscription = local.watchTasks('u').listen((tasks) {
      if (tasks.isEmpty) {
        unawaited(local.upsertTask('u', task));
      } else if (!observed.isCompleted) {
        observed.complete(tasks);
      }
    });
    addTearDown(subscription.cancel);
    expect(
        (await observed.future.timeout(const Duration(seconds: 2))).single.id,
        task.id);
  });
}
