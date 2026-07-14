class TaskListGroup {
  const TaskListGroup({
    required this.id,
    required this.userId,
    required this.name,
    this.isCollapsed = false,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final bool isCollapsed;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskListGroup copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isCollapsed,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskListGroup(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
