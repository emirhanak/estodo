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
        .map((s) => s.docs.map(TaskDto.fromFirestore).toList());
  }

  Stream<List<TodoTask>> watchTasksForList(String ownerId, String listId) {
    return _userDoc(ownerId)
        .collection('tasks')
        .where('listId', isEqualTo: listId)
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
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

  Future<void> deleteList(String userId, String listId) async {
    final userDoc = _userDoc(userId);
    final tasks = await userDoc
        .collection('tasks')
        .where('listId', isEqualTo: listId)
        .limit(450)
        .get();
    final batch = _firestore.batch();
    batch.delete(userDoc.collection('lists').doc(listId));
    for (final task in tasks.docs) {
      batch.update(task.reference, {
        'listId': null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    // Remove share code entry
    batch.delete(_firestore.collection('share_lookup').doc(listId));
    await batch.commit();
  }

  Future<void> resetExpiredMyDay(String userId, String todayKey) async {
    final snapshot = await _userDoc(userId)
        .collection('tasks')
        .where('isMyDay', isEqualTo: true)
        .limit(450)
        .get();
    final batch = _firestore.batch();
    var hasUpdates = false;
    for (final doc in snapshot.docs) {
      if (doc.data()['myDayDate'] != todayKey) {
        hasUpdates = true;
        batch.update(doc.reference, {
          'isMyDay': false,
          'myDayDate': null,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    }
    if (hasUpdates) await batch.commit();
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
        .map((s) => s.docs.map(TaskListDto.fromFirestore).toList());
  }

  Future<void> upsertList(String userId, TaskList list) {
    return _userDoc(userId)
        .collection('lists')
        .doc(list.id)
        .set(TaskListDto.toFirestore(list), SetOptions(merge: true));
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
    batch.delete(
        _userDoc(userId).collection('list_groups').doc(groupId));
    await batch.commit();
  }

  // ── Sharing ───────────────────────────────────────────────────────────────

  Future<void> publishShareCode(String ownerId, String listId) {
    return _firestore.collection('share_lookup').doc(listId).set(
      {
        'ownerId': ownerId,
        'listId': listId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }

  Future<({String ownerId, String listId})?> resolveShareCode(
      String code) async {
    final doc =
        await _firestore.collection('share_lookup').doc(code.trim()).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return (
      ownerId: data['ownerId'] as String,
      listId: data['listId'] as String,
    );
  }

  Future<TaskList?> fetchList(String ownerId, String listId) async {
    final doc = await _userDoc(ownerId).collection('lists').doc(listId).get();
    if (!doc.exists) return null;
    return TaskListDto.fromFirestore(doc);
  }

  Future<void> addMember(
      String ownerId, String listId, String memberUid) async {
    await _userDoc(ownerId).collection('lists').doc(listId).update({
      'memberIds': FieldValue.arrayUnion([memberUid]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> removeMember(
      String ownerId, String listId, String memberUid) async {
    await _userDoc(ownerId).collection('lists').doc(listId).update({
      'memberIds': FieldValue.arrayRemove([memberUid]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<TaskList>> watchSharedLists(String userId) {
    return _userDoc(userId)
        .collection('list_memberships')
        .snapshots()
        .asyncMap((snapshot) async {
      final lists = <TaskList>[];
      for (final doc in snapshot.docs) {
        final ownerId = doc.data()['ownerId'] as String?;
        if (ownerId == null) continue;
        final list = await fetchList(ownerId, doc.id);
        if (list != null) lists.add(list);
      }
      return lists;
    });
  }

  Future<void> saveListMembership(
      String userId, String ownerId, String listId) {
    return _userDoc(userId).collection('list_memberships').doc(listId).set({
      'ownerId': ownerId,
      'listId': listId,
      'joinedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> removeListMembership(String userId, String listId) {
    return _userDoc(userId)
        .collection('list_memberships')
        .doc(listId)
        .delete();
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }
}
