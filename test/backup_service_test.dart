import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:estodo/core/services/backup_service.dart';
import 'package:estodo/features/tasks/domain/entities/task_list.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/presentation/providers/task_providers.dart';

class _FakeTaskController implements TaskController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BackupService', () {
    test('exportToJson serializes tasks and lists into valid JSON format', () {
      final now = DateTime.now();
      final lists = [
        TaskList(
          id: 'list-1',
          userId: 'user-1',
          name: 'Personal',
          color: 0xFF123456,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final tasks = [
        TodoTask(
          id: 'task-1',
          userId: 'user-1',
          listId: 'list-1',
          title: 'Buy groceries #shopping',
          tags: ['shopping'],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final jsonString = BackupService.exportToJson(
        tasks: tasks,
        lists: lists,
      );

      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      expect(decoded['app'], 'estodo');
      expect(decoded['version'], 1);
      expect(decoded['lists'], hasLength(1));
      expect(decoded['tasks'], hasLength(1));
      expect(decoded['tasks'][0]['title'], 'Buy groceries #shopping');
      expect(decoded['tasks'][0]['tags'], contains('shopping'));
    });

    test('importFromJson throws FormatException on invalid payload', () async {
      final fakeController = _FakeTaskController();
      expect(
        BackupService.importFromJson(
          '{"invalid": true}',
          controller: fakeController,
          existingLists: const [],
          existingTasks: const [],
        ),
        throwsFormatException,
      );
    });
  });
}
