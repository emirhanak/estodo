import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_provider.dart';
import '../../domain/entities/todo_task.dart';
import '../providers/task_providers.dart';

enum FocusTimerStatus { idle, running, paused, completed }

enum FocusTimerMode {
  pomodoro(Duration(minutes: 25)),
  shortBreak(Duration(minutes: 5)),
  longBreak(Duration(minutes: 15)),
  custom(Duration(minutes: 30));

  const FocusTimerMode(this.defaultDuration);
  final Duration defaultDuration;
}

class FocusTimerState {
  const FocusTimerState({
    this.task,
    this.status = FocusTimerStatus.idle,
    this.mode = FocusTimerMode.pomodoro,
    this.totalDuration = const Duration(minutes: 25),
    this.remainingDuration = const Duration(minutes: 25),
    this.completedPomodoros = 0,
  });

  final TodoTask? task;
  final FocusTimerStatus status;
  final FocusTimerMode mode;
  final Duration totalDuration;
  final Duration remainingDuration;
  final int completedPomodoros;

  bool get isRunning => status == FocusTimerStatus.running;
  bool get isPaused => status == FocusTimerStatus.paused;
  bool get isCompleted => status == FocusTimerStatus.completed;
  bool get isActive =>
      status == FocusTimerStatus.running || status == FocusTimerStatus.paused;

  double get progress {
    if (totalDuration.inSeconds == 0) return 0.0;
    final elapsed = totalDuration.inSeconds - remainingDuration.inSeconds;
    return (elapsed / totalDuration.inSeconds).clamp(0.0, 1.0);
  }

  String get formattedTime {
    final minutes = remainingDuration.inMinutes;
    final seconds = remainingDuration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  FocusTimerState copyWith({
    TodoTask? task,
    FocusTimerStatus? status,
    FocusTimerMode? mode,
    Duration? totalDuration,
    Duration? remainingDuration,
    int? completedPomodoros,
    bool clearTask = false,
  }) {
    return FocusTimerState(
      task: clearTask ? null : (task ?? this.task),
      status: status ?? this.status,
      mode: mode ?? this.mode,
      totalDuration: totalDuration ?? this.totalDuration,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
    );
  }
}

class FocusTimerController extends Notifier<FocusTimerState> {
  Timer? _ticker;

  @override
  FocusTimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const FocusTimerState();
  }

  void start({
    required TodoTask task,
    FocusTimerMode mode = FocusTimerMode.pomodoro,
    Duration? customDuration,
  }) {
    _ticker?.cancel();
    final duration = customDuration ??
        (task.durationMinutes != null && task.durationMinutes! > 0
            ? Duration(minutes: task.durationMinutes!)
            : mode.defaultDuration);

    state = FocusTimerState(
      task: task,
      mode: mode,
      status: FocusTimerStatus.running,
      totalDuration: duration,
      remainingDuration: duration,
      completedPomodoros: state.completedPomodoros,
    );

    HapticFeedback.mediumImpact();
    _startTicker();
  }

  void pause() {
    if (!state.isRunning) return;
    _ticker?.cancel();
    HapticFeedback.lightImpact();
    state = state.copyWith(status: FocusTimerStatus.paused);
  }

  void resume() {
    if (!state.isPaused) return;
    HapticFeedback.lightImpact();
    state = state.copyWith(status: FocusTimerStatus.running);
    _startTicker();
  }

  void togglePlayPause() {
    if (state.isRunning) {
      pause();
    } else if (state.isPaused) {
      resume();
    } else if (state.task != null) {
      start(task: state.task!, mode: state.mode);
    }
  }

  void reset() {
    _ticker?.cancel();
    HapticFeedback.selectionClick();
    state = state.copyWith(
      status: FocusTimerStatus.idle,
      remainingDuration: state.totalDuration,
    );
  }

  void addMinutes(int minutes) {
    HapticFeedback.selectionClick();
    final extra = Duration(minutes: minutes);
    state = state.copyWith(
      totalDuration: state.totalDuration + extra,
      remainingDuration: state.remainingDuration + extra,
    );
  }

  void switchMode(FocusTimerMode newMode, {Duration? duration}) {
    _ticker?.cancel();
    HapticFeedback.selectionClick();
    final targetDuration = duration ?? newMode.defaultDuration;
    state = state.copyWith(
      mode: newMode,
      status: FocusTimerStatus.idle,
      totalDuration: targetDuration,
      remainingDuration: targetDuration,
    );
  }

  void skipToNext() {
    _ticker?.cancel();
    HapticFeedback.mediumImpact();
    if (state.mode == FocusTimerMode.pomodoro) {
      final nextPomos = state.completedPomodoros + 1;
      final nextMode = (nextPomos % 4 == 0)
          ? FocusTimerMode.longBreak
          : FocusTimerMode.shortBreak;
      state = state.copyWith(
        mode: nextMode,
        status: FocusTimerStatus.idle,
        totalDuration: nextMode.defaultDuration,
        remainingDuration: nextMode.defaultDuration,
        completedPomodoros: nextPomos,
      );
    } else {
      state = state.copyWith(
        mode: FocusTimerMode.pomodoro,
        status: FocusTimerStatus.idle,
        totalDuration: FocusTimerMode.pomodoro.defaultDuration,
        remainingDuration: FocusTimerMode.pomodoro.defaultDuration,
      );
    }
  }

  Future<void> completeTask() async {
    final task = state.task;
    if (task == null) return;
    HapticFeedback.heavyImpact();
    await ref.read(taskControllerProvider).toggleComplete(task);
    _ticker?.cancel();
    state = state.copyWith(
      status: FocusTimerStatus.completed,
      completedPomodoros: state.completedPomodoros + 1,
    );
  }

  void stop() {
    _ticker?.cancel();
    HapticFeedback.selectionClick();
    state = const FocusTimerState();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingDuration.inSeconds <= 1) {
        _onTimerFinished();
      } else {
        state = state.copyWith(
          remainingDuration:
              state.remainingDuration - const Duration(seconds: 1),
        );
      }
    });
  }

  void _onTimerFinished() {
    _ticker?.cancel();
    HapticFeedback.vibrate();

    final isPomo = state.mode == FocusTimerMode.pomodoro;
    final newCompleted =
        isPomo ? state.completedPomodoros + 1 : state.completedPomodoros;

    state = state.copyWith(
      status: FocusTimerStatus.completed,
      remainingDuration: Duration.zero,
      completedPomodoros: newCompleted,
    );

    try {
      ref.read(notificationServiceProvider).showInstantNotification(
            title: isPomo
                ? '🍅 Odaklanma Seansı Tamamlandı!'
                : '☕ Mola Sona Erdi!',
            body: isPomo
                ? '${state.task?.title ?? "Görev"} üzerinde harika bir ilerleme kaydettin.'
                : 'Yenilendin! Bir sonraki odak seansına başlamaya hazır mısın?',
          );
    } catch (_) {}
  }
}

final focusTimerProvider =
    NotifierProvider<FocusTimerController, FocusTimerState>(
  FocusTimerController.new,
);
