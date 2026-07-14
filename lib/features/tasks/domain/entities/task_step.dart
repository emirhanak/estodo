class TaskStep {
  const TaskStep({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final bool isCompleted;

  TaskStep copyWith({String? id, String? title, bool? isCompleted}) {
    return TaskStep(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  static TaskStep fromMap(Map<dynamic, dynamic> data) {
    return TaskStep(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
    );
  }
}
