import '../../domain/entities/list_sort_option.dart';
import '../../domain/entities/todo_task.dart';

class TaskSorter {
  const TaskSorter._();

  static List<TodoTask> sort(
    List<TodoTask> tasks, {
    required ListSortOption option,
    required bool ascending,
  }) {
    final sorted = List<TodoTask>.from(tasks);
    int compare(TodoTask a, TodoTask b) {
      switch (option) {
        case ListSortOption.manual:
          final pos = a.position.compareTo(b.position);
          if (pos != 0) return pos;
          return b.createdAt.compareTo(a.createdAt);
        case ListSortOption.importance:
          if (a.isImportant != b.isImportant) {
            return a.isImportant ? -1 : 1;
          }
          return b.createdAt.compareTo(a.createdAt);
        case ListSortOption.dueDate:
          final aDue = a.dueAt;
          final bDue = b.dueAt;
          if (aDue == null && bDue == null) return 0;
          if (aDue == null) return 1;
          if (bDue == null) return -1;
          return aDue.compareTo(bDue);
        case ListSortOption.alphabetical:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case ListSortOption.creationDate:
          return a.createdAt.compareTo(b.createdAt);
        case ListSortOption.myDay:
          if (a.isMyDay != b.isMyDay) {
            return a.isMyDay ? -1 : 1;
          }
          return b.createdAt.compareTo(a.createdAt);
      }
    }

    sorted.sort((a, b) {
      final c = compare(a, b);
      return ascending ? c : -c;
    });
    return sorted;
  }
}
