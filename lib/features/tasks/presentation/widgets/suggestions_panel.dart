import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_time_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/todo_task.dart';
import '../providers/task_providers.dart';

class SuggestionsPanel extends ConsumerStatefulWidget {
  const SuggestionsPanel({
    super.key,
    required this.accent,
    required this.tasks,
  });

  final Color accent;
  final List<TodoTask> tasks;

  @override
  ConsumerState<SuggestionsPanel> createState() => _SuggestionsPanelState();
}

class _SuggestionsPanelState extends ConsumerState<SuggestionsPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final today = DateTimeFormatter.todayKey();
    final suggestions = widget.tasks.where((task) {
      if (task.isCompleted) return false;
      if (task.isInMyDay(today)) return false;
      if (task.dueAt != null) {
        final due = task.dueAt!;
        if (due.isBefore(DateTime.now().add(const Duration(days: 3)))) {
          return true;
        }
      }
      final ageDays = DateTime.now().difference(task.createdAt).inDays;
      if (ageDays >= 1 && ageDays <= 7) return true;
      return false;
    }).take(8).toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: widget.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: widget.accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _expanded
                            ? l10n.suggestionsTitle
                            : l10n.suggestionsCount(suggestions.length),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: widget.accent,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: widget.accent,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  children: [
                    for (final task in suggestions)
                      _SuggestionTile(
                        task: task,
                        accent: widget.accent,
                        onAdd: () => ref
                            .read(taskControllerProvider)
                            .toggleMyDay(task),
                      ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  l10n.suggestionsHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.task,
    required this.accent,
    required this.onAdd,
  });

  final TodoTask task;
  final Color accent;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        dense: true,
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: task.dueAt == null
            ? null
            : Text(
                DateTimeFormatter.dueLabel(
                  task.dueAt!,
                  locale: Localizations.localeOf(context).languageCode,
                ),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
        trailing: IconButton(
          tooltip: 'Add to My Day',
          icon: Icon(Icons.add_circle_outline_rounded, color: accent),
          onPressed: onAdd,
        ),
      ),
    );
  }
}
