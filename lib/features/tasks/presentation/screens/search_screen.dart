import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/task_list.dart';
import '../../domain/entities/todo_task.dart';
import '../providers/task_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_editor_sheet.dart';
import '../widgets/task_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.onOpenList});

  final ValueChanged<TaskList> onOpenList;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  var _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider).value ?? const <TodoTask>[];
    final lists = ref.watch(listsProvider).value ?? const <TaskList>[];
    final normalized = _query.trim().toLowerCase();
    final l10n = AppLocalizations.of(context);
    final matchingTasks = normalized.isEmpty
        ? const <TodoTask>[]
        : tasks.where((task) {
            return task.title.toLowerCase().contains(normalized) ||
                (task.notes ?? '').toLowerCase().contains(normalized);
          }).toList();
    final matchingLists = normalized.isEmpty
        ? const <TaskList>[]
        : lists
            .where((list) => list.name.toLowerCase().contains(normalized))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.clear,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  setState(() => _query = value);
                });
              },
          ),
        ),
        Expanded(
          child: normalized.isEmpty
              ? EmptyState(
                  icon: Icons.search_rounded,
                  title: l10n.emptySearchTitle,
                  message: l10n.emptySearchBody,
                )
              : _SearchResults(
                  tasks: matchingTasks,
                  lists: matchingLists,
                  onOpenList: widget.onOpenList,
                ),
        ),
      ],
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.tasks,
    required this.lists,
    required this.onOpenList,
  });

  final List<TodoTask> tasks;
  final List<TaskList> lists;
  final ValueChanged<TaskList> onOpenList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final allLists = ref.watch(listsProvider).value ?? const <TaskList>[];
    if (tasks.isEmpty && lists.isEmpty) {
      return EmptyState(
        icon: Icons.manage_search_rounded,
        title: l10n.noMatchesTitle,
        message: l10n.noMatchesBody,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (lists.isNotEmpty) ...[
          _SectionLabel(label: l10n.lists),
          for (final list in lists)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(list.color),
                child: const Icon(Icons.list_rounded, color: Colors.white),
              ),
              title: Text(list.name),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onOpenList(list),
            ),
        ],
        if (tasks.isNotEmpty) ...[
          _SectionLabel(label: l10n.tasks),
          for (final task in tasks)
            Builder(builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              Color accent = scheme.primary;
              String? listLabel;
              for (final list in allLists) {
                if (list.id == task.listId) {
                  accent = Color(list.color);
                  listLabel = list.name;
                  break;
                }
              }
              return TaskTile(
                task: task,
                accent: accent,
                listLabel: listLabel,
                onToggleComplete: () =>
                    ref.read(taskControllerProvider).toggleComplete(task),
                onToggleImportant: () =>
                    ref.read(taskControllerProvider).toggleImportant(task),
                onToggleMyDay: () =>
                    ref.read(taskControllerProvider).toggleMyDay(task),
                onEdit: () => showTaskEditorSheet(context, task: task),
                onDelete: () =>
                    ref.read(taskControllerProvider).deleteTask(task),
              );
            }),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
