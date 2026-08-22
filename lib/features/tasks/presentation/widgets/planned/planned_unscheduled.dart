import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/todo_task.dart';
import '../../utils/planned_layout.dart';
import 'planned_capsule.dart';
import 'planned_format.dart';

/// Compact row of day tasks that have no start time yet — the mobile
/// counterpart of Structured's inbox bubbles.
class PlannedUnscheduledStrip extends StatelessWidget {
  const PlannedUnscheduledStrip({
    super.key,
    required this.entries,
    required this.accent,
    required this.onOpen,
  });

  final List<PlannedEntry> entries;
  final Color accent;
  final void Function(TodoTask task) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
            child: Text(
              '${l10n.plannedUnscheduled} · ${entries.length}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) => _UnscheduledBubble(
                entry: entries[index],
                onOpen: () => onOpen(entries[index].task),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnscheduledBubble extends StatelessWidget {
  const _UnscheduledBubble({required this.entry, required this.onOpen});

  final PlannedEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubble = SizedBox(
      width: 82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(entry.icon, color: entry.color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            entry.task.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  height: 1.15,
                ),
          ),
        ],
      ),
    );

    return LongPressDraggable<TodoTask>(
      data: entry.task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: PlannedDragFeedback(entry: entry),
      childWhenDragging: Opacity(opacity: 0.35, child: bubble),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: bubble,
      ),
    );
  }
}

/// What follows the finger while a task is dragged onto the timeline.
class PlannedDragFeedback extends StatelessWidget {
  const PlannedDragFeedback({super.key, required this.entry});

  final PlannedEntry entry;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-90, -26),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: entry.color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: entry.color.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                entry.icon,
                size: 18,
                color: PlannedCapsule.foregroundOn(entry.color),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  entry.task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PlannedCapsule.foregroundOn(entry.color),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sidebar inbox used on tablets: unscheduled work for the selected day.
class PlannedInboxPanel extends StatelessWidget {
  const PlannedInboxPanel({
    super.key,
    required this.day,
    required this.accent,
    required this.onOpen,
    required this.onToggle,
    required this.onSchedule,
  });

  final PlannedDay day;
  final Color accent;
  final void Function(TodoTask task) onOpen;
  final void Function(TodoTask task) onToggle;
  final void Function(TodoTask task) onSchedule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 6),
          child: Row(
            children: [
              Icon(Icons.inbox_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                l10n.plannedUnscheduled,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${day.unscheduled.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
          child: Text(
            l10n.plannedUnscheduledHint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
            children: [
              for (final entry in day.unscheduled)
                _InboxCard(
                  entry: entry,
                  accent: accent,
                  onOpen: () => onOpen(entry.task),
                  onSchedule: () => onSchedule(entry.task),
                ),
              if (day.unscheduled.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  child: Text(
                    l10n.plannedDayEmpty,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              if (day.completed.isNotEmpty)
                PlannedCompletedSection(
                  entries: day.completed,
                  accent: accent,
                  onOpen: onOpen,
                  onToggle: onToggle,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.entry,
    required this.accent,
    required this.onOpen,
    required this.onSchedule,
  });

  final PlannedEntry entry;
  final Color accent;
  final VoidCallback onOpen;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final card = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(entry.icon, size: 18, color: entry.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  PlannedFormat.duration(l10n, entry.durationMinutes),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                Text(
                  entry.task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.startTime,
            onPressed: onSchedule,
            icon: Icon(Icons.add_rounded, color: accent),
          ),
        ],
      ),
    );

    return LongPressDraggable<TodoTask>(
      data: entry.task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: PlannedDragFeedback(entry: entry),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: card,
      ),
    );
  }
}

/// Collapsible list of the day's finished tasks.
class PlannedCompletedSection extends StatefulWidget {
  const PlannedCompletedSection({
    super.key,
    required this.entries,
    required this.accent,
    required this.onOpen,
    required this.onToggle,
  });

  final List<PlannedEntry> entries;
  final Color accent;
  final void Function(TodoTask task) onOpen;
  final void Function(TodoTask task) onToggle;

  @override
  State<PlannedCompletedSection> createState() =>
      _PlannedCompletedSectionState();
}

class _PlannedCompletedSectionState extends State<PlannedCompletedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (value) => setState(() => _expanded = value),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.only(bottom: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: 0.45),
          collapsedBackgroundColor:
              scheme.surfaceContainerHigh.withValues(alpha: 0.45),
          title: Text(
            l10n.completedCount(widget.entries.length),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          children: [
            for (final entry in widget.entries)
              ListTile(
                dense: true,
                onTap: () => widget.onOpen(entry.task),
                leading: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: entry.color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.check_rounded, size: 16, color: entry.color),
                ),
                title: Text(
                  entry.task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                trailing: IconButton(
                  tooltip: l10n.completed,
                  icon:
                      Icon(Icons.undo_rounded, size: 18, color: scheme.outline),
                  onPressed: () => widget.onToggle(entry.task),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
