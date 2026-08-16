import '../entities/task_list.dart';
import '../entities/todo_task.dart';

abstract interface class TaskRepository {
  Stream<List<TodoTask>> watchTasks(String userId);

  Stream<List<TaskList>> watchLists(String userId);

  Future<void> createTask(String userId, TodoTask task);

  Future<void> updateTask(String userId, TodoTask task);

  Future<void> deleteTask(String userId, String taskId);

  Future<void> createList(String userId, TaskList list);

  Future<void> updateList(String userId, TaskList list);

  Future<void> deleteList(String userId, String listId);

  Future<void> carryOverExpiredMyDay(String userId, String todayKey);

  Future<void> registerDeviceToken(String userId, String token);
}
