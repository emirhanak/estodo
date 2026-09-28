import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/presentation/utils/focus_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTask = TodoTask(
    id: 'test-focus-task',
    userId: 'user-1',
    title: 'Code Focus Mode',
    durationMinutes: 45,
    createdAt: DateTime(2026, 9, 28),
    updatedAt: DateTime(2026, 9, 28),
  );

  test('Initial focus timer state is idle', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(focusTimerProvider);
    expect(state.status, FocusTimerStatus.idle);
    expect(state.isActive, isFalse);
    expect(state.task, isNull);
  });

  test('Start initializes running state with custom task duration', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(focusTimerProvider.notifier);
    controller.start(task: testTask);

    final state = container.read(focusTimerProvider);
    expect(state.status, FocusTimerStatus.running);
    expect(state.isActive, isTrue);
    expect(state.isRunning, isTrue);
    expect(state.task?.id, 'test-focus-task');
    expect(state.totalDuration.inMinutes, 45);
    expect(state.remainingDuration.inMinutes, 45);
    expect(state.formattedTime, '45:00');
  });

  test('Pause and resume toggle between paused and running', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(focusTimerProvider.notifier);
    controller.start(task: testTask);
    controller.pause();

    var state = container.read(focusTimerProvider);
    expect(state.status, FocusTimerStatus.paused);
    expect(state.isPaused, isTrue);
    expect(state.isActive, isTrue);

    controller.resume();
    state = container.read(focusTimerProvider);
    expect(state.status, FocusTimerStatus.running);
    expect(state.isRunning, isTrue);
  });

  test('addMinutes increases both total and remaining duration', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(focusTimerProvider.notifier);
    controller.start(task: testTask);
    controller.addMinutes(5);

    final state = container.read(focusTimerProvider);
    expect(state.totalDuration.inMinutes, 50);
    expect(state.remainingDuration.inMinutes, 50);
    expect(state.formattedTime, '50:00');
  });

  test('switchMode updates mode and default durations', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(focusTimerProvider.notifier);
    controller.start(task: testTask);
    controller.switchMode(FocusTimerMode.shortBreak);

    var state = container.read(focusTimerProvider);
    expect(state.mode, FocusTimerMode.shortBreak);
    expect(state.totalDuration.inMinutes, 5);
    expect(state.remainingDuration.inMinutes, 5);
    expect(state.status, FocusTimerStatus.idle);

    controller.switchMode(FocusTimerMode.longBreak);
    state = container.read(focusTimerProvider);
    expect(state.mode, FocusTimerMode.longBreak);
    expect(state.totalDuration.inMinutes, 15);
  });

  test('skipToNext advances pomodoro cycle to break and back', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(focusTimerProvider.notifier);
    controller.start(
      task: testTask,
      mode: FocusTimerMode.pomodoro,
      customDuration: const Duration(minutes: 25),
    );

    controller.skipToNext();
    var state = container.read(focusTimerProvider);
    expect(state.mode, FocusTimerMode.shortBreak);
    expect(state.completedPomodoros, 1);
    expect(state.totalDuration.inMinutes, 5);

    controller.skipToNext();
    state = container.read(focusTimerProvider);
    expect(state.mode, FocusTimerMode.pomodoro);
    expect(state.totalDuration.inMinutes, 25);
  });

  test('stop clears task and resets state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(focusTimerProvider.notifier);
    controller.start(task: testTask);
    controller.stop();

    final state = container.read(focusTimerProvider);
    expect(state.status, FocusTimerStatus.idle);
    expect(state.task, isNull);
    expect(state.isActive, isFalse);
  });
}
