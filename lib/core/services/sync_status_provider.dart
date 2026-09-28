import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tasks/presentation/providers/task_providers.dart';
import 'connectivity_provider.dart';

enum SyncStatus {
  synced,
  syncing,
  offline,
}

class SyncState {
  const SyncState({
    required this.status,
    required this.lastSyncedAt,
    this.message,
  });

  final SyncStatus status;
  final DateTime lastSyncedAt;
  final String? message;

  bool get isSynced => status == SyncStatus.synced;
  bool get isSyncing => status == SyncStatus.syncing;
  bool get isOffline => status == SyncStatus.offline;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? message,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: message ?? this.message,
    );
  }
}

final syncStatusProvider =
    NotifierProvider<SyncStatusController, SyncState>(SyncStatusController.new);

class SyncStatusController extends Notifier<SyncState> {
  DateTime _lastSynced = DateTime.now();
  bool _isManualSyncing = false;

  @override
  SyncState build() {
    final isOnline = ref.watch(onlineStatusProvider).value ?? true;
    if (!isOnline) {
      return SyncState(
        status: SyncStatus.offline,
        lastSyncedAt: _lastSynced,
      );
    }

    if (_isManualSyncing) {
      return SyncState(
        status: SyncStatus.syncing,
        lastSyncedAt: _lastSynced,
      );
    }

    final tasksAsync = ref.watch(tasksProvider);
    final listsAsync = ref.watch(listsProvider);

    final isLoading = tasksAsync.isLoading || listsAsync.isLoading;
    if (isLoading && !tasksAsync.hasValue) {
      return SyncState(
        status: SyncStatus.syncing,
        lastSyncedAt: _lastSynced,
      );
    }

    if (tasksAsync.hasValue || listsAsync.hasValue) {
      _lastSynced = DateTime.now();
    }

    return SyncState(
      status: SyncStatus.synced,
      lastSyncedAt: _lastSynced,
    );
  }

  Future<void> triggerSync() async {
    final isOnline = ref.read(onlineStatusProvider).value ?? true;
    if (!isOnline) {
      state = SyncState(
        status: SyncStatus.offline,
        lastSyncedAt: _lastSynced,
      );
      return;
    }

    _isManualSyncing = true;
    state = SyncState(
      status: SyncStatus.syncing,
      lastSyncedAt: _lastSynced,
    );

    // Invalidate providers to force remote refresh
    ref.invalidate(tasksProvider);
    ref.invalidate(listsProvider);

    // Smooth minimum visual delay for user feedback
    await Future<void>.delayed(const Duration(milliseconds: 600));

    _isManualSyncing = false;
    _lastSynced = DateTime.now();
    state = SyncState(
      status: SyncStatus.synced,
      lastSyncedAt: _lastSynced,
    );
  }

  void markSyncing() {
    final isOnline = ref.read(onlineStatusProvider).value ?? true;
    if (!isOnline) return;
    state = state.copyWith(status: SyncStatus.syncing);
  }

  void markSynced() {
    final isOnline = ref.read(onlineStatusProvider).value ?? true;
    if (!isOnline) return;
    _lastSynced = DateTime.now();
    state = state.copyWith(
      status: SyncStatus.synced,
      lastSyncedAt: _lastSynced,
    );
  }
}
