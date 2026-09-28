import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:estodo/core/services/connectivity_provider.dart';
import 'package:estodo/core/services/sync_status_provider.dart';
import 'package:estodo/features/tasks/domain/entities/task_list.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/presentation/providers/task_providers.dart';

void main() {
  test('Sync status reports offline when onlineStatusProvider is false',
      () async {
    final container = ProviderContainer(
      overrides: [
        onlineStatusProvider.overrideWith((ref) => Stream.value(false)),
        tasksProvider.overrideWith((ref) => Stream.value(const <TodoTask>[])),
        listsProvider.overrideWith((ref) => Stream.value(const <TaskList>[])),
      ],
    );
    addTearDown(container.dispose);

    container.listen(syncStatusProvider, (_, __) {});
    await pumpEventQueue();

    final syncState = container.read(syncStatusProvider);
    expect(syncState.status, SyncStatus.offline);
    expect(syncState.isOffline, isTrue);
    expect(syncState.isSynced, isFalse);
    expect(syncState.isSyncing, isFalse);
  });

  test('Sync status reports synced when online and tasks stream has value',
      () async {
    final container = ProviderContainer(
      overrides: [
        onlineStatusProvider.overrideWith((ref) => Stream.value(true)),
        tasksProvider.overrideWith((ref) => Stream.value(const <TodoTask>[])),
        listsProvider.overrideWith((ref) => Stream.value(const <TaskList>[])),
      ],
    );
    addTearDown(container.dispose);

    container.listen(syncStatusProvider, (_, __) {});
    await pumpEventQueue();

    final syncState = container.read(syncStatusProvider);
    expect(syncState.status, SyncStatus.synced);
    expect(syncState.isSynced, isTrue);
    expect(syncState.isOffline, isFalse);
  });

  test('triggerSync transitions through syncing to synced', () async {
    final container = ProviderContainer(
      overrides: [
        onlineStatusProvider.overrideWith((ref) => Stream.value(true)),
        tasksProvider.overrideWith((ref) => Stream.value(const <TodoTask>[])),
        listsProvider.overrideWith((ref) => Stream.value(const <TaskList>[])),
      ],
    );
    addTearDown(container.dispose);

    container.listen(syncStatusProvider, (_, __) {});
    await pumpEventQueue();

    final controller = container.read(syncStatusProvider.notifier);

    final syncFuture = controller.triggerSync();
    expect(container.read(syncStatusProvider).status, SyncStatus.syncing);
    expect(container.read(syncStatusProvider).isSyncing, isTrue);

    await syncFuture;
    expect(container.read(syncStatusProvider).status, SyncStatus.synced);
    expect(container.read(syncStatusProvider).isSynced, isTrue);
  });

  test('markSyncing and markSynced manually update state', () {
    final container = ProviderContainer(
      overrides: [
        onlineStatusProvider.overrideWith((ref) => Stream.value(true)),
        tasksProvider.overrideWith((ref) => Stream.value(const <TodoTask>[])),
        listsProvider.overrideWith((ref) => Stream.value(const <TaskList>[])),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(syncStatusProvider.notifier);
    controller.markSyncing();
    expect(container.read(syncStatusProvider).isSyncing, isTrue);

    controller.markSynced();
    expect(container.read(syncStatusProvider).isSynced, isTrue);
  });
}
