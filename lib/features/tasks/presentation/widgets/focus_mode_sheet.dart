import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/task_step.dart';
import '../../domain/entities/todo_task.dart';
import '../providers/task_providers.dart';
import '../utils/focus_session_controller.dart';
import 'confetti_burst.dart';

Future<void> showFocusModeSheet(
  BuildContext context, {
  required TodoTask task,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => FocusModeSheet(task: task),
  );
}

class FocusModeSheet extends ConsumerStatefulWidget {
  const FocusModeSheet({super.key, required this.task});

  final TodoTask task;

  @override
  ConsumerState<FocusModeSheet> createState() => _FocusModeSheetState();
}

class _FocusModeSheetState extends ConsumerState<FocusModeSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(focusTimerProvider);
      if (current.task?.id != widget.task.id ||
          current.status == FocusTimerStatus.idle) {
        ref.read(focusTimerProvider.notifier).start(task: widget.task);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(focusTimerProvider);
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final task = timerState.task ?? widget.task;
    final accent = task.colorValue != null
        ? Color(task.colorValue!)
        : (task.isHabit ? Colors.deepOrange : scheme.primary);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                  tooltip: l10n.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        task.isHabit
                            ? Icons.autorenew_rounded
                            : Icons.timer_outlined,
                        size: 15,
                        color: accent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.focusMode,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  tooltip: l10n.focusReset,
                  onPressed: () =>
                      ref.read(focusTimerProvider.notifier).reset(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Task Title
                  Text(
                    task.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                  ),
                  if (task.notes != null && task.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.notes!,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Mode Switcher Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _modeChip(
                          context,
                          title: '🍅 ${l10n.focusPomodoro}',
                          active: timerState.mode == FocusTimerMode.pomodoro,
                          accent: accent,
                          onTap: () => ref
                              .read(focusTimerProvider.notifier)
                              .switchMode(FocusTimerMode.pomodoro),
                        ),
                        const SizedBox(width: 8),
                        _modeChip(
                          context,
                          title: '☕ ${l10n.focusShortBreak}',
                          active: timerState.mode == FocusTimerMode.shortBreak,
                          accent: accent,
                          onTap: () => ref
                              .read(focusTimerProvider.notifier)
                              .switchMode(FocusTimerMode.shortBreak),
                        ),
                        const SizedBox(width: 8),
                        _modeChip(
                          context,
                          title: '🌴 ${l10n.focusLongBreak}',
                          active: timerState.mode == FocusTimerMode.longBreak,
                          accent: accent,
                          onTap: () => ref
                              .read(focusTimerProvider.notifier)
                              .switchMode(FocusTimerMode.longBreak),
                        ),
                        if (task.durationMinutes != null &&
                            task.durationMinutes! != 25) ...[
                          const SizedBox(width: 8),
                          _modeChip(
                            context,
                            title: '⏱️ ${task.durationMinutes} dk',
                            active: timerState.mode == FocusTimerMode.custom,
                            accent: accent,
                            onTap: () => ref
                                .read(focusTimerProvider.notifier)
                                .switchMode(
                                  FocusTimerMode.custom,
                                  duration:
                                      Duration(minutes: task.durationMinutes!),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Big Circular Arc Timer
                  Center(
                    child: SizedBox(
                      width: 230,
                      height: 230,
                      child: CustomPaint(
                        painter: _TimerArcPainter(
                          progress: timerState.progress,
                          accent: accent,
                          trackColor:
                              scheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timerState.formattedTime,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _statusLabel(timerState, l10n),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              // Pomodoro cycle dots
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var i = 0; i < 4; i++) ...[
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (i <
                                                (timerState.completedPomodoros %
                                                    4))
                                            ? accent
                                            : scheme.outlineVariant
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Play / Pause / Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // +5 Min Chip
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () =>
                            ref.read(focusTimerProvider.notifier).addMinutes(5),
                        child: Text(
                          l10n.focusAdd5Min,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 18),

                      // Play / Pause Button
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(20),
                          shape: const CircleBorder(),
                          elevation: 4,
                          shadowColor: accent.withValues(alpha: 0.4),
                        ),
                        onPressed: () => ref
                            .read(focusTimerProvider.notifier)
                            .togglePlayPause(),
                        child: Icon(
                          timerState.isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 18),

                      // Skip Button
                      IconButton.outlined(
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.skip_next_rounded, size: 24),
                        onPressed: () =>
                            ref.read(focusTimerProvider.notifier).skipToNext(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Subtasks checklist if present
                  if (task.hasSteps) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.focusSubtasks,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (final step in task.steps)
                            _StepCheckTile(
                              step: step,
                              accent: accent,
                              onToggle: () => _toggleStep(task, step),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Complete Task Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        showConfettiBurst(
                          context,
                          position:
                              MediaQuery.of(context).size.center(Offset.zero),
                          accent: accent,
                        );
                        await ref
                            .read(focusTimerProvider.notifier)
                            .completeTask();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.focusSessionDone,
                              ),
                            ),
                          );
                          await Future.delayed(
                              const Duration(milliseconds: 600));
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            l10n.focusCompleteTask,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(
    BuildContext context, {
    required String title,
    required bool active,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? accent
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: active ? Colors.white : scheme.onSurfaceVariant,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
        ),
      ),
    );
  }

  String _statusLabel(FocusTimerState state, AppLocalizations l10n) {
    if (state.isCompleted) return l10n.completed;
    if (state.isPaused) return l10n.focusPause;
    if (state.isRunning) {
      return state.mode == FocusTimerMode.pomodoro
          ? l10n.focusPomodoro
          : (state.mode == FocusTimerMode.shortBreak
              ? l10n.focusShortBreak
              : l10n.focusLongBreak);
    }
    return l10n.focusStart;
  }

  Future<void> _toggleStep(TodoTask task, TaskStep step) async {
    HapticFeedback.lightImpact();
    final updatedSteps = task.steps.map((s) {
      if (s.id == step.id) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    final updatedTask = task.copyWith(steps: updatedSteps);
    await ref.read(taskControllerProvider).updateTask(updatedTask);
  }
}

class _StepCheckTile extends StatelessWidget {
  const _StepCheckTile({
    required this.step,
    required this.accent,
    required this.onToggle,
  });

  final TaskStep step;
  final Color accent;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              step.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              size: 20,
              color: step.isCompleted ? accent : scheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration:
                          step.isCompleted ? TextDecoration.lineThrough : null,
                      color: step.isCompleted
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerArcPainter extends CustomPainter {
  _TimerArcPainter({
    required this.progress,
    required this.accent,
    required this.trackColor,
  });

  final double progress;
  final Color accent;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Glowing Arc
    final arcPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.trackColor != trackColor;
  }
}
