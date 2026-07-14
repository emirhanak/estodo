import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/task_list_group.dart';

class TaskListGroupDto {
  const TaskListGroupDto._();

  static TaskListGroup fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  static TaskListGroup fromMap(String id, Map<String, dynamic> data) {
    return TaskListGroup(
      id: data['id'] as String? ?? id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? 'Group',
      isCollapsed: data['isCollapsed'] as bool? ?? false,
      position: (data['position'] as num?)?.toInt() ?? 0,
      createdAt: _dateFrom(data['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFrom(data['updatedAt']) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toFirestore(TaskListGroup group) {
    return {
      'id': group.id,
      'userId': group.userId,
      'name': group.name,
      'isCollapsed': group.isCollapsed,
      'position': group.position,
      'createdAt': Timestamp.fromDate(group.createdAt),
      'updatedAt': Timestamp.fromDate(group.updatedAt),
    };
  }

  static DateTime? _dateFrom(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
