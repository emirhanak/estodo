import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/preferences_provider.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/todo_task.dart';
import '../../utils/planned_layout.dart';
import '../animated_check_circle.dart';
import '../confetti_burst.dart';
import 'planned_capsule.dart';
import 'planned_format.dart';
import 'planned_unscheduled.dart';
import '../../utils/streak_calculator.dart';
import '../focus_mode_sheet.dart';

/// A single scheduled task on the day timeline: time gutter, duration capsule
/// and the task card.
class PlannedEntryRow extends ConsumerStatefulWidget {
  const PlannedEntryRow({
    super.key,
    required this.entry,
    required this.now,
    required this.onOpen,
    required this.onToggle,
    this.onDropped,
    this.gutterWidth = 52,
    this.connectorTop = true,
    this.connectorBottom = true,
  });

  final PlannedEntry entry;
  final DateTime now;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final void Function(TodoTask task)? onDropped;
  final double gutterWidth;
  final bool connectorTop;
  final bool connectorBottom;

  @override
  ConsumerState<PlannedEntryRow> createState() => _PlannedEntryRowState();
}

class _PlannedEntryRowState extends ConsumerState<PlannedEntryRow> {
  final _checkKey = GlobalKey();

  void _toggle() {
    final entry = widget.entry;
    if (ref.read(confettiEnabledProvider) && !entry.isCompleted) {
      final box = _checkKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && mounted) {
        showConfettiBurst(
          context,
          position: box.localToGlobal(box.size.center(Offset.zero)),
          accent: entry.color,
        );
      }
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final height = PlannedLayout.capsuleHeight(entry.durationMinutes);
    final active = entry.isActiveAt(widget.now);
    final start = entry.start;
    final end = entry.end;
    final isPast = !active && end != null && widget.now.isAfter(end);
    final rowOpacity = entry.isCompleted ? 0.65 : (isPast ? 0.78 : 1.0);

    final subtitle = active
        ? l10n.plannedRemaining(entry.remainingMinutesAt(widget.now))
        : PlannedFormat.range(l10n, entry);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: widget.gutterWidth,
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  start == null ? '' : PlannedFormat.time(start),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: active ? entry.color : scheme.onSurfaceVariant,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                ),
              ),
              const Spacer(),
              if (height >= 84 && end != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10, bottom: 2),
                  child: Text(
                    PlannedFormat.time(end),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                  ),
                ),
            ],
          ),
        ),
        PlannedCapsule(
          entry: entry,
          height: height,
          progress: active ? entry.progressAt(widget.now) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: active
                                          ? entry.color
                                          : scheme.onSurfaceVariant,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                              ),
                            ),
                            if (active) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => showFocusModeSheet(context,
                                    task: entry.task),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: entry.color.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.play_arrow_rounded,
                                          size: 12, color: entry.color),
                                      const SizedBox(width: 2),
                                      Text(
                                        l10n.focusMode,
                                        style: TextStyle(
                                          color: entry.color,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    color: entry.isCompleted
                                        ? scheme.onSurfaceVariant
                                        : scheme.onSurface,
                                    decoration: entry.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationThickness: 2,
                                  ),
                        ),
                        _MetaRow(entry: entry),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 4),
                    child: KeyedSubtree(
                      key: _checkKey,
                      child: AnimatedCheckCircle(
                        value: entry.isCompleted,
                        color: entry.color,
                        size: 24,
                        onChanged: (_) => _toggle(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    final interactive = Semantics(
      button: true,
      label: '${entry.task.title}, $subtitle',
      child: InkWell(
        onTap: widget.onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              left: widget.gutterWidth + PlannedCapsule.columnWidth / 2 - 1,
              top: widget.connectorTop ? 0 : 10,
              bottom: widget.connectorBottom ? 0 : 10,
              width: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.outlineVariant.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: rowOpacity < 1.0
                  ? Opacity(opacity: rowOpacity, child: row)
                  : row,
            ),
          ],
        ),
      ),
    );

    Widget content = interactive;
    if (widget.onDropped != null) {
      content = DragTarget<TodoTask>(
        onWillAcceptWithDetails: (details) {
          if (details.data.id == entry.task.id) return false;
          HapticFeedback.selectionClick();
          return true;
        },
        onAcceptWithDetails: (details) {
          HapticFeedback.mediumImpact();
          widget.onDropped?.call(details.data);
        },
        builder: (context, candidate, _) {
          final hovering = candidate.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: hovering
                  ? entry.color.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: hovering
                  ? Border.all(color: entry.color, width: 1.5)
                  : null,
            ),
            child: interactive,
          );
        },
      );
    }

    if (entry.isCompleted) return content;
    return LongPressDraggable<TodoTask>(
      data: entry.task,
      onDragStarted: () => HapticFeedback.mediumImpact(),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: PlannedDragFeedback(entry: entry),
      childWhenDragging: Opacity(opacity: 0.28, child: content),
      child: content,
    );
  }
}

class _MetaRow extends ConsumerWidget {
  const _MetaRow({required this.entry});

  final PlannedEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final task = entry.task;
    final chips = <Widget>[];
    final streakSummary = ref.watch(streakProvider);

    if (entry.listName != null) {
      chips.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: entry.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              entry.listName!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }
    if (task.hasSteps) {
      final completed = task.completedStepsCount;
      final total = task.steps.length;
      final isDone = completed == total && total > 0;
      chips.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                value: total > 0 ? (completed / total).clamp(0.0, 1.0) : 0,
                strokeWidth: 2.0,
                backgroundColor: entry.color.withValues(alpha: 0.22),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? Colors.teal : entry.color,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$completed/$total',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDone ? Colors.teal : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }
    if (task.reminderAt != null) {
      chips.add(_icon(context, Icons.notifications_none_rounded, null));
    }
    if (task.isHabit) {
      final habitStreak = streakSummary.habitStreak(task);
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: entry.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.autorenew_rounded, size: 11, color: entry.color),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context).composerKindHabit,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: entry.color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (habitStreak > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '· 🔥$habitStreak',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: entry.color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (task.recurrence != null) {
      final streak = streakSummary.habitStreak(task);
      chips.add(_icon(
        context,
        Icons.repeat_rounded,
        streak > 0 ? '🔥$streak' : null,
      ));
    }
    if (task.isImportant) {
      chips.add(Icon(Icons.star_rounded, size: 14, color: scheme.tertiary));
    }
    if (task.notes != null && task.notes!.trim().isNotEmpty) {
      chips.add(_icon(context, Icons.notes_rounded, null));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 12, runSpacing: 4, children: chips),
    );
  }

  Widget _icon(BuildContext context, IconData icon, String? label) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
