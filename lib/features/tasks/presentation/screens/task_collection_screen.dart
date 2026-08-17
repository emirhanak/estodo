import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_time_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/list_sort_option.dart';
import '../../domain/entities/task_list.dart';
import '../../domain/entities/todo_task.dart';
import '../providers/selection_provider.dart';
import '../providers/task_providers.dart';
import '../utils/task_sorter.dart';
import '../widgets/empty_state.dart';
import '../widgets/multi_select_bar.dart';
import '../widgets/my_day_banner.dart';
import '../widgets/quick_add_field.dart';
import '../widgets/suggestions_panel.dart';
import '../widgets/task_editor_sheet.dart';
import '../widgets/task_tile.dart';

enum CollectionLayout { flat, planned, completedArchive }

class TaskCollectionScreen extends ConsumerStatefulWidget {
  const TaskCollectionScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.filter,
    this.subtitle,
    this.list,
    this.accent,
    this.layout = CollectionLayout.flat,
    this.showQuickAdd = true,
    this.quickAddPrefill,
    this.headerActions = const <Widget>[],
    this.showSuggestions = false,
    this.showMyDayBanner = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String emptyTitle;
  final String emptyMessage;
  final bool Function(TodoTask task) filter;
  final TaskList? list;
  final Color? accent;
  final CollectionLayout layout;
  final bool showQuickAdd;
  final QuickAddPrefill? quickAddPrefill;
  final List<Widget> headerActions;
  final bool showSuggestions;
  final bool showMyDayBanner;

  @override
  ConsumerState<TaskCollectionScreen> createState() =>
      _TaskCollectionScreenState();
}

class _TaskCollectionScreenState extends ConsumerState<TaskCollectionScreen> {
  bool _completedExpanded = false;
  DateTime _plannedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final listsAsync = ref.watch(listsProvider);
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accent ??
        (widget.list != null ? Color(widget.list!.color) : scheme.primary);

    final selection = ref.watch(taskSelectionProvider);

    return Container(
      color: scheme.surface,
      child: Stack(
        children: [
          tasksAsync.when(
            data: (tasks) {
              final filtered = tasks.where(widget.filter).toList();
              final lists = listsAsync.value ?? const <TaskList>[];
              return RefreshIndicator(
                color: accent,
                onRefresh: () async {
                  ref.invalidate(tasksProvider);
                  ref.invalidate(listsProvider);
                  await Future<void>.delayed(const Duration(milliseconds: 300));
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (widget.showMyDayBanner)
                      SliverToBoxAdapter(child: MyDayBanner(accent: accent))
                    else if (MediaQuery.sizeOf(context).width >= 720)
                      SliverToBoxAdapter(
                        child: _Header(
                          title: widget.title,
                          subtitle: widget.subtitle,
                          icon: widget.icon,
                          accent: accent,
                          actions: widget.headerActions,
                        ),
                      ),
                    if (widget.showSuggestions)
                      SliverToBoxAdapter(
                        child: SuggestionsPanel(accent: accent, tasks: tasks),
                      ),
                    if (widget.showQuickAdd && !selection.isNotEmpty)
                      SliverToBoxAdapter(
                        child: QuickAddField(
                          accent: accent,
                          prefill: widget.quickAddPrefill,
                        ),
                      ),
                    ..._buildContent(context, filtered, lists, accent),
                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                ),
              );
            },
            error: (_, __) => Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: l10n.errorCouldNotLoadTasks,
                  message: l10n.errorTryAgain,
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          if (selection.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: MultiSelectBar(accent: accent),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    List<TodoTask> filtered,
    List<TaskList> lists,
    Color accent,
  ) {
    if (widget.layout == CollectionLayout.planned) {
      return _buildPlanned(filtered, lists, accent);
    }
    if (widget.layout == CollectionLayout.completedArchive) {
      final sorted = List<TodoTask>.from(filtered)
        ..sort((a, b) {
          final aDate = a.completedAt ?? a.updatedAt;
          final bDate = b.completedAt ?? b.updatedAt;
          return bDate.compareTo(aDate);
        });
      return [_buildList(sorted, lists, accent, allowReorder: false)];
    }

    final option = widget.list?.sortOption ?? ListSortOption.manual;
    final ascending = widget.list?.sortAscending ?? true;
    final active = filtered.where((t) => !t.isCompleted).toList();
    final completed = filtered.where((t) => t.isCompleted).toList();

    final sortedActive = TaskSorter.sort(
      active,
      option: option,
      ascending: ascending,
    );

    final children = <Widget>[];
    if (sortedActive.isEmpty && completed.isEmpty) {
      children.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: widget.icon,
            title: widget.emptyTitle,
            message: widget.emptyMessage,
          ),
        ),
      );
    } else {
      children.add(_buildList(
        sortedActive,
        lists,
        accent,
        allowReorder: option == ListSortOption.manual,
      ));
      if (completed.isNotEmpty) {
        children.add(_buildCompletedSection(completed, lists, accent));
      }
    }

    return children;
  }

  Widget _buildList(
    List<TodoTask> tasks,
    List<TaskList> lists,
    Color accent, {
    bool allowReorder = false,
  }) {
    if (allowReorder && tasks.length > 1) {
      return SliverReorderableList(
        itemCount: tasks.length,
        // ignore: deprecated_member_use
        onReorder: (oldIndex, newIndex) async {
          final mutable = List<TodoTask>.from(tasks);
          final ix = newIndex > oldIndex ? newIndex - 1 : newIndex;
          final moved = mutable.removeAt(oldIndex);
          mutable.insert(ix, moved);
          await ref.read(taskControllerProvider).reorderTasks(mutable);
        },
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ReorderableDelayedDragStartListener(
            key: ValueKey('reorder-task-${task.id}'),
            index: index,
            child: _buildTile(task, lists, accent),
          );
        },
      );
    }

    return SliverList.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTile(task, lists, accent);
      },
    );
  }

  Widget _buildTile(TodoTask task, List<TaskList> lists, Color accent) {
    String? listLabel;
    if (widget.list == null && task.listId != null) {
      for (final entry in lists) {
        if (entry.id == task.listId) {
          listLabel = entry.name;
          break;
        }
      }
    }
    final tileAccent = task.listId == null
        ? accent
        : Color(
            lists
                .where((l) => l.id == task.listId)
                .map((l) => l.color)
                .firstWhere((_) => true, orElse: () => accent.toARGB32()),
          );
    final selection = ref.read(taskSelectionProvider);
    return TaskTile(
      key: ValueKey('task-tile-${task.id}'),
      task: task,
      accent: tileAccent,
      listLabel: listLabel,
      selected: selection.contains(task.id),
      selectionActive: selection.isNotEmpty,
      onToggleComplete: () =>
          ref.read(taskControllerProvider).toggleComplete(task),
      onToggleImportant: () =>
          ref.read(taskControllerProvider).toggleImportant(task),
      onToggleMyDay: () => ref.read(taskControllerProvider).toggleMyDay(task),
      onEdit: () {
        if (selection.isNotEmpty) {
          ref.read(taskSelectionProvider.notifier).toggle(task.id);
        } else {
          showTaskEditorSheet(context, task: task);
        }
      },
      onLongPress: () =>
          ref.read(taskSelectionProvider.notifier).toggle(task.id),
      onDelete: () => _confirmDelete(context, task),
    );
  }

  List<Widget> _buildPlanned(
    List<TodoTask> tasks,
    List<TaskList> lists,
    Color accent,
  ) {
    final l10n = AppLocalizations.of(context);
    final widgets = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: CalendarDatePicker(
              initialDate: _plannedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              onDateChanged: (date) => setState(() => _plannedDate = date),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Text(
            l10n.upcomingPlans,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    ];
    if (tasks.isEmpty) {
      widgets.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: widget.icon,
            title: widget.emptyTitle,
            message: widget.emptyMessage,
          ),
        ),
      );
      return widgets;
    }
    final groups = <PlannedBucket, List<TodoTask>>{};
    for (final task in tasks) {
      if (task.dueAt == null) continue;
      final bucket = DateTimeFormatter.plannedBucket(task.dueAt!);
      groups.putIfAbsent(bucket, () => <TodoTask>[]).add(task);
    }

    for (final bucket in PlannedBucket.values) {
      final entries = groups[bucket];
      if (entries == null || entries.isEmpty) continue;
      entries.sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              _bucketLabel(bucket, l10n),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      );
      widgets.add(_buildList(entries, lists, accent));
    }
    return widgets;
  }

  String _bucketLabel(PlannedBucket bucket, AppLocalizations l10n) {
    return switch (bucket) {
      PlannedBucket.earlier => l10n.bucketEarlier,
      PlannedBucket.today => l10n.bucketToday,
      PlannedBucket.tomorrow => l10n.bucketTomorrow,
      PlannedBucket.thisWeek => l10n.bucketThisWeek,
      PlannedBucket.later => l10n.bucketLater,
    };
  }

  Widget _buildCompletedSection(
    List<TodoTask> completed,
    List<TaskList> lists,
    Color accent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          listTileTheme: ListTileTheme.of(context).copyWith(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
          child: ExpansionTile(
            initiallyExpanded: _completedExpanded,
            onExpansionChanged: (value) =>
                setState(() => _completedExpanded = value),
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: EdgeInsets.zero,
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            collapsedBackgroundColor:
                scheme.surfaceContainerHigh.withValues(alpha: 0.5),
            backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
            title: Text(
              l10n.completedCount(completed.length),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            children: [
              ...completed.map((task) => _buildTile(task, lists, accent)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TodoTask task) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTaskConfirmTitle),
        content: Text(l10n.deleteTaskConfirmBody(task.title)),
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

    if (confirmed == true) {
      await ref.read(taskControllerProvider).deleteTask(task);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.icon,
    required this.accent,
    this.subtitle,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...actions,
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 2),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
