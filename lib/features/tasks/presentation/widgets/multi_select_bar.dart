import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/task_list.dart';
import '../../domain/entities/todo_task.dart';
import '../providers/selection_provider.dart';
import '../providers/task_providers.dart';

class MultiSelectBar extends ConsumerWidget {
  const MultiSelectBar({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(taskSelectionProvider);
    final tasks = ref.watch(tasksProvider).value ?? const <TodoTask>[];
    final lists = ref.watch(listsProvider).value ?? const <TaskList>[];
    final selected = tasks.where((t) => selection.contains(t.id)).toList();
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(14),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.close,
                  icon: Icon(Icons.close_rounded, color: scheme.onInverseSurface),
                  onPressed: () =>
                      ref.read(taskSelectionProvider.notifier).clear(),
                ),
                Expanded(
                  child: Text(
                    l10n.selectedCount(selection.length),
                    style: TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _IconAction(
                  icon: Icons.check_rounded,
                  tooltip: l10n.complete,
                  color: scheme.onInverseSurface,
                  onPressed: () async {
                    final allCompleted = selected.every((t) => t.isCompleted);
                    await ref
                        .read(taskControllerProvider)
                        .bulkComplete(selected, completed: !allCompleted);
                    ref.read(taskSelectionProvider.notifier).clear();
                  },
                ),
                _IconAction(
                  icon: Icons.star_rounded,
                  tooltip: l10n.markImportant,
                  color: scheme.onInverseSurface,
                  onPressed: () async {
                    final allStarred = selected.every((t) => t.isImportant);
                    await ref
                        .read(taskControllerProvider)
                        .bulkImportant(selected, important: !allStarred);
                    ref.read(taskSelectionProvider.notifier).clear();
                  },
                ),
                _IconAction(
                  icon: Icons.wb_sunny_outlined,
                  tooltip: l10n.addToMyDay,
                  color: scheme.onInverseSurface,
                  onPressed: () async {
                    await ref
                        .read(taskControllerProvider)
                        .bulkMyDay(selected, addToMyDay: true);
                    ref.read(taskSelectionProvider.notifier).clear();
                  },
                ),
                _IconAction(
                  icon: Icons.drive_file_move_outline,
                  tooltip: l10n.moveTo,
                  color: scheme.onInverseSurface,
                  onPressed: () async {
                    final picked = await _pickList(context, lists);
                    if (picked == null) return;
                    await ref
                        .read(taskControllerProvider)
                        .bulkMoveToList(selected, picked == '' ? null : picked);
                    ref.read(taskSelectionProvider.notifier).clear();
                  },
                ),
                _IconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: l10n.delete,
                  color: scheme.error,
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.deleteTaskConfirmTitle),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await ref
                        .read(taskControllerProvider)
                        .bulkDelete(selected);
                    ref.read(taskSelectionProvider.notifier).clear();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _pickList(BuildContext context, List<TaskList> lists) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.inbox_rounded),
                title: Text(l10n.tasks),
                onTap: () => Navigator.of(context).pop(''),
              ),
              const Divider(height: 1),
              for (final list in lists)
                ListTile(
                  leading: CircleAvatar(
                    radius: 8,
                    backgroundColor: Color(list.color),
                  ),
                  title: Text(list.name),
                  onTap: () => Navigator.of(context).pop(list.id),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: color),
      onPressed: onPressed,
    );
  }
}
