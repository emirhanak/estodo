import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/list_sort_option.dart';
import '../../domain/entities/task_list.dart';

class TaskListDto {
  const TaskListDto._();

  static TaskList fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  static TaskList fromLocal(String id, Map<dynamic, dynamic> data) {
    return fromMap(id, Map<String, dynamic>.from(data));
  }

  static TaskList fromMap(String id, Map<String, dynamic> data) {
    return TaskList(
      id: data['id'] as String? ?? id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? 'List',
      color: data['color'] as int? ?? 0xFF8E8CD8,
      sortOption: _sortFrom(data['sortOption']),
      sortAscending: data['sortAscending'] as bool? ?? true,
      position: (data['position'] as num?)?.toInt() ?? 0,
      groupId: data['groupId'] as String?,
      background: data['background'] as String?,
      memberIds: (data['memberIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      createdAt: _dateFrom(data['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFrom(data['updatedAt']) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toFirestore(TaskList list) {
    return {
      'id': list.id,
      'userId': list.userId,
      'name': list.name,
      'color': list.color,
      'sortOption': list.sortOption.name,
      'sortAscending': list.sortAscending,
      'position': list.position,
      'groupId': list.groupId,
      'background': list.background,
      'memberIds': list.memberIds,
      'createdAt': Timestamp.fromDate(list.createdAt),
      'updatedAt': Timestamp.fromDate(list.updatedAt),
    };
  }

  static Map<String, dynamic> toLocal(TaskList list) {
    return {
      'id': list.id,
      'userId': list.userId,
      'name': list.name,
      'color': list.color,
      'sortOption': list.sortOption.name,
      'sortAscending': list.sortAscending,
      'position': list.position,
      'groupId': list.groupId,
      'background': list.background,
      'memberIds': list.memberIds,
      'createdAt': list.createdAt.toIso8601String(),
      'updatedAt': list.updatedAt.toIso8601String(),
    };
  }

  static DateTime? _dateFrom(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static ListSortOption _sortFrom(Object? value) {
    if (value is! String) return ListSortOption.manual;
    return ListSortOption.values.firstWhere(
      (option) => option.name == value,
      orElse: () => ListSortOption.manual,
    );
  }
}
