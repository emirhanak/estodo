import 'package:estodo/features/tasks/domain/entities/list_sort_option.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/presentation/utils/task_sorter.dart';
import 'package:flutter_test/flutter_test.dart';

TodoTask _task(
  String id, {
  int position = 0,
  int createdDay = 1,
  bool isImportant = false,
  bool isMyDay = false,
  DateTime? dueAt,
}) {
  final created = DateTime(2026, 10, createdDay);
  return TodoTask(
    id: id,
    userId: 'u',
    title: id,
    position: position,
    isImportant: isImportant,
    isMyDay: isMyDay,
    dueAt: dueAt,
    createdAt: created,
    updatedAt: created,
  );
}

List<String> _ids(
  List<TodoTask> tasks,
  ListSortOption option, {
  bool ascending = true,
}) =>
    TaskSorter.sort(tasks, option: option, ascending: ascending)
        .map((t) => t.id)
        .toList();

void main() {
  test('manual orders by position, then newest first', () {
    final tasks = [
      _task('b', position: 1),
      _task('old', createdDay: 1),
      _task('new', createdDay: 5),
    ];
    expect(_ids(tasks, ListSortOption.manual), ['new', 'old', 'b']);
  });

  test('importance puts starred tasks first', () {
    final tasks = [_task('plain'), _task('star', isImportant: true)];
    expect(_ids(tasks, ListSortOption.importance), ['star', 'plain']);
  });

  test('due date puts undated tasks last', () {
    final tasks = [
      _task('none'),
      _task('late', dueAt: DateTime(2026, 10, 9)),
      _task('soon', dueAt: DateTime(2026, 10, 3)),
    ];
    expect(_ids(tasks, ListSortOption.dueDate), ['soon', 'late', 'none']);
  });

  test('alphabetical ignores case and descending reverses', () {
    final tasks = [_task('beta'), _task('Alpha'), _task('gamma')];
    expect(
        _ids(tasks, ListSortOption.alphabetical), ['Alpha', 'beta', 'gamma']);
    expect(
      _ids(tasks, ListSortOption.alphabetical, ascending: false),
      ['gamma', 'beta', 'Alpha'],
    );
  });

  test('creation date and My Day', () {
    final tasks = [
      _task('second', createdDay: 2),
      _task('first', createdDay: 1, isMyDay: true),
    ];
    expect(_ids(tasks, ListSortOption.creationDate), ['first', 'second']);
    expect(_ids(tasks, ListSortOption.myDay), ['first', 'second']);
  });

  test('does not modify the input list', () {
    final tasks = [_task('b'), _task('a')];
    TaskSorter.sort(tasks,
        option: ListSortOption.alphabetical, ascending: true);
    expect(tasks.map((t) => t.id), ['b', 'a']);
  });
}
