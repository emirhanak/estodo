import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/focus_session_controller.dart';
import 'focus_mode_sheet.dart';

class FocusMiniBar extends ConsumerWidget {
  const FocusMiniBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(focusTimerProvider);
    if (!timerState.isActive || timerState.task == null) {
      return const SizedBox.shrink();
    }

    final task = timerState.task!;
    final scheme = Theme.of(context).colorScheme;
    final accent = task.colorValue != null
        ? Color(task.colorValue!)
        : (task.isHabit ? Colors.deepOrange : scheme.primary);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          color: scheme.surfaceContainerHigh,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showFocusModeSheet(context, task: task),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  // Animated progress ring or pulse
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      value: timerState.progress,
                      strokeWidth: 3,
                      backgroundColor:
                          scheme.outlineVariant.withValues(alpha: 0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Time
                  Text(
                    timerState.formattedTime,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: accent,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  // Play/Pause
                  IconButton(
                    iconSize: 22,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      timerState.isRunning
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: accent,
                    ),
                    onPressed: () => ref
                        .read(focusTimerProvider.notifier)
                        .togglePlayPause(),
                  ),
                  // Stop/Dismiss
                  IconButton(
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        ref.read(focusTimerProvider.notifier).stop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
