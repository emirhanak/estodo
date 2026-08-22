import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/preferences_provider.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/todo_task.dart';
import '../../utils/planned_layout.dart';
import '../animated_check_circle.dart';
import '../confetti_burst.dart';
import 'planned_capsule.dart';
import 'planned_format.dart';

/// A single scheduled task on the day timeline: time gutter, duration capsule
/// and the task card.
class PlannedEntryRow extends ConsumerStatefulWidget {
  const PlannedEntryRow({
    super.key,
    required this.entry,
    required this.now,
    required this.onOpen,
    required this.onToggle,
    this.gutterWidth = 52,
    this.connectorTop = true,
    this.connectorBottom = true,
  });

  final PlannedEntry entry;
  final DateTime now;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
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
                        Text(
                          subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: active
                                    ? entry.color
                                    : scheme.onSurfaceVariant,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                              ),
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
              child: row,
            ),
          ],
        ),
      ),
    );

    if (entry.isCompleted) return interactive;
    return LongPressDraggable<TodoTask>(
      data: entry.task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(entry.task.title),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.28, child: interactive),
      child: interactive,
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.entry});

  final PlannedEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final task = entry.task;
    final chips = <Widget>[];

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
      chips.add(_icon(
        context,
        Icons.checklist_rounded,
        '${task.completedStepsCount}/${task.steps.length}',
      ));
    }
    if (task.reminderAt != null) {
      chips.add(_icon(context, Icons.notifications_none_rounded, null));
    }
    if (task.recurrence != null) {
      chips.add(_icon(context, Icons.repeat_rounded, null));
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
