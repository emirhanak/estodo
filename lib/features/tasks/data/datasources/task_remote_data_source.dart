import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/task_list.dart';
import '../../domain/entities/task_list_group.dart';
import '../../domain/entities/todo_task.dart';
import '../models/task_dto.dart';
import '../models/task_list_dto.dart';
import '../models/task_list_group_dto.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Stream<List<TodoTask>> watchTasks(String userId) {
    return _userDoc(userId)
        .collection('tasks')
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        // Local echoes can be rolled back when the backend rejects a write.
        // Only committed server results may acknowledge or remove local data.
        .where((s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites)
        .map((s) => s.docs.map(TaskDto.fromFirestore).toList());
  }

  Future<void> upsertTask(String userId, TodoTask task) {
    return _userDoc(userId)
        .collection('tasks')
        .doc(task.id)
        .set(TaskDto.toFirestore(task), SetOptions(merge: true));
  }

  Future<void> deleteTask(String userId, String taskId) {
    return _userDoc(userId).collection('tasks').doc(taskId).delete();
  }

  Future<void> registerDeviceToken(String userId, String token) {
    return _userDoc(userId).collection('devices').doc(token).set(
      {
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }

  // ── Lists ─────────────────────────────────────────────────────────────────

  Stream<List<TaskList>> watchLists(String userId) {
    return _userDoc(userId)
        .collection('lists')
        .orderBy('name')
        .snapshots(includeMetadataChanges: true)
        // Same rule as tasks: only committed server results may acknowledge
        // or remove locally pending lists.
        .where((s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites)
        .map((s) => s.docs.map(TaskListDto.fromFirestore).toList());
  }

  Future<void> upsertList(String userId, TaskList list) {
    return _userDoc(userId)
        .collection('lists')
        .doc(list.id)
        .set(TaskListDto.toFirestore(list), SetOptions(merge: true));
  }

  /// Deletes only the list document. The repository re-homes the list's
  /// tasks as individual pending uploads, which works offline and is not
  /// capped by a batch size.
  Future<void> deleteList(String userId, String listId) {
    return _userDoc(userId).collection('lists').doc(listId).delete();
  }

  // ── Groups ────────────────────────────────────────────────────────────────

  Stream<List<TaskListGroup>> watchGroups(String userId) {
    return _userDoc(userId)
        .collection('list_groups')
        .orderBy('position')
        .snapshots(includeMetadataChanges: true)
        .map((s) => s.docs.map(TaskListGroupDto.fromFirestore).toList());
  }

  Future<void> upsertGroup(String userId, TaskListGroup group) {
    return _userDoc(userId)
        .collection('list_groups')
        .doc(group.id)
        .set(TaskListGroupDto.toFirestore(group), SetOptions(merge: true));
  }

  Future<void> deleteGroup(String userId, String groupId) async {
    // Ungroup all lists that belong to this group
    final lists = await _userDoc(userId)
        .collection('lists')
        .where('groupId', isEqualTo: groupId)
        .get();
    final batch = _firestore.batch();
    for (final doc in lists.docs) {
      batch.update(doc.reference, {'groupId': null});
    }
    batch.delete(_userDoc(userId).collection('list_groups').doc(groupId));
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }
}
