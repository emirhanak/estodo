import 'package:estodo/features/tasks/domain/entities/task_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('task priority labels are stable', () {
    expect(TaskPriority.low.label, 'Low');
    expect(TaskPriority.medium.label, 'Medium');
    expect(TaskPriority.high.label, 'High');
  });
}
