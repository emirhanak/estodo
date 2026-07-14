import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/preferences_provider.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/todo_task.dart';
import 'animated_check_circle.dart';
import 'confetti_burst.dart';

class TaskTile extends ConsumerStatefulWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.accent,
    required this.onToggleComplete,
    required this.onToggleImportant,
    required this.onToggleMyDay,
    required this.onEdit,
    required this.onDelete,
    this.onLongPress,
    this.listLabel,
    this.selected = false,
    this.selectionActive = false,
  });

  final TodoTask task;
  final Color accent;
  final VoidCallback onToggleComplete;
  final VoidCallback onToggleImportant;
  final VoidCallback onToggleMyDay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final String? listLabel;
  final bool selected;
  final bool selectionActive;

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile> {
  final _checkKey = GlobalKey();

  void _handleToggleComplete() {
    if (ref.read(confettiEnabledProvider) && !widget.task.isCompleted) {
      final box = _checkKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && mounted) {
        final pos = box.localToGlobal(box.size.center(Offset.zero));
        showConfettiBurst(context, position: pos, accent: widget.accent);
      }
    }
    widget.onToggleComplete();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final accent = widget.accent;
    final selected = widget.selected;
    final selectionActive = widget.selectionActive;

    final scheme = Theme.of(context).colorScheme;
    final completed = task.isCompleted;
    final titleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          decoration: completed ? TextDecoration.lineThrough : null,
          decorationThickness: 2,
          color: completed ? scheme.onSurfaceVariant : scheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        );

    final isMyDay = task.isInMyDay(DateTimeFormatter.todayKey());
    final l10n = AppLocalizations.of(context);
    final tileColor = selected
        ? accent.withValues(alpha: 0.18)
        : scheme.surfaceContainerLowest;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(10),
        border: selected ? Border.all(color: accent, width: 1.5) : null,
        boxShadow: selected
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onEdit,
          onLongPress: widget.onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: selectionActive
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            color: selected ? accent : scheme.outline,
                            size: 26,
                          ),
                        )
                      : KeyedSubtree(
                          key: _checkKey,
                          child: AnimatedCheckCircle(
                            value: completed,
                            color: accent,
                            onChanged: (_) => _handleToggleComplete(),
                          ),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 10, 4, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: titleStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_metaItems(context, scheme, isMyDay).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              children: _metaItems(context, scheme, isMyDay),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!selectionActive)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: task.isImportant
                        ? l10n.removeImportance
                        : l10n.markImportant,
                    icon: Icon(
                      task.isImportant
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color:
                          task.isImportant ? accent : scheme.onSurfaceVariant,
                      size: 22,
                    ),
                    onPressed: widget.onToggleImportant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selectionActive) {
      return card;
    }

    return Dismissible(
      key: ValueKey('task-${task.id}'),
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: accent.withValues(alpha: 0.85),
        icon: Icons.check_rounded,
        label: completed ? l10n.undo : l10n.complete,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: scheme.tertiary.withValues(alpha: 0.85),
        icon: isMyDay ? Icons.cloud_off_rounded : Icons.wb_sunny_rounded,
        label: isMyDay ? l10n.removeFromDay : l10n.addToMyDay,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _handleToggleComplete();
        } else {
          widget.onToggleMyDay();
        }
        return false;
      },
      child: card,
    );
  }

  List<Widget> _metaItems(
    BuildContext context,
    ColorScheme scheme,
    bool isMyDay,
  ) {
    final task = widget.task;
    final items = <Widget>[];
    final locale = Localizations.localeOf(context).languageCode;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        );

    if (widget.listLabel != null) {
      items.add(
          _metaText(Icons.list_rounded, widget.listLabel!, scheme, textStyle));
    }
    if (task.dueAt != null) {
      final now = DateTime.now();
      final overdue = !task.isCompleted &&
          task.dueAt!.isBefore(DateTime(now.year, now.month, now.day));
      items.add(
        _metaText(
          Icons.event_outlined,
          DateTimeFormatter.dueLabel(task.dueAt!, locale: locale),
          scheme,
          textStyle?.copyWith(
            color: overdue ? scheme.error : scheme.onSurfaceVariant,
            fontWeight: overdue ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      );
    }
    if (task.reminderAt != null) {
      items.add(
        _metaText(
          Icons.notifications_active_outlined,
          DateTimeFormatter.timeLabel(task.reminderAt!),
          scheme,
          textStyle,
        ),
      );
    }
    if (task.recurrence != null) {
      items.add(
        _metaText(
            Icons.repeat_rounded, task.recurrence!.label, scheme, textStyle),
      );
    }
    if (task.hasSteps) {
      items.add(
        _metaText(
          Icons.checklist_rounded,
          '${task.completedStepsCount}/${task.steps.length}',
          scheme,
          textStyle,
        ),
      );
    }
    if ((task.notes ?? '').isNotEmpty) {
      items.add(_metaText(Icons.notes_rounded, 'Note', scheme, textStyle));
    }
    if (isMyDay) {
      items.add(
        _metaText(Icons.wb_sunny_outlined, 'My Day', scheme, textStyle),
      );
    }
    return items;
  }

  Widget _metaText(
    IconData icon,
    String label,
    ColorScheme scheme,
    TextStyle? style,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: style?.color ?? scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: style),
      ],
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
