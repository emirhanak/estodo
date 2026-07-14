import 'list_sort_option.dart';

class TaskList {
  const TaskList({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    this.sortOption = ListSortOption.manual,
    this.sortAscending = true,
    this.position = 0,
    this.groupId,
    this.background,
    this.memberIds = const <String>[],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final int color;
  final ListSortOption sortOption;
  final bool sortAscending;
  final int position;
  final String? groupId;
  final String? background;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isShared => memberIds.isNotEmpty;

  TaskList copyWith({
    String? id,
    String? userId,
    String? name,
    int? color,
    ListSortOption? sortOption,
    bool? sortAscending,
    int? position,
    Object? groupId = _sentinel,
    Object? background = _sentinel,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOption: sortOption ?? this.sortOption,
      sortAscending: sortAscending ?? this.sortAscending,
      position: position ?? this.position,
      groupId: groupId == _sentinel ? this.groupId : groupId as String?,
      background:
          background == _sentinel ? this.background : background as String?,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const _sentinel = Object();
