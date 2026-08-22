import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final locale = Localizations.localeOf(context).languageCode;
    final weekStart = _weekStart(_plannedDate, locale);
    final week = List<DateTime>.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    final selected = tasks
        .where((task) =>
            task.dueAt != null && DateUtils.isSameDay(task.dueAt, _plannedDate))
        .toList()
      ..sort(_plannedTaskCompare);
    final upcoming = tasks
        .where((task) =>
            task.dueAt != null &&
            task.dueAt!.isAfter(DateTime(
                _plannedDate.year, _plannedDate.month, _plannedDate.day)))
        .toList()
      ..sort(_plannedTaskCompare);

    final widgets = <Widget>[
      SliverToBoxAdapter(
        child: _WeekHeader(
          weekStart: weekStart,
          locale: locale,
          onPrevious: () => setState(
              () => _plannedDate = weekStart.subtract(const Duration(days: 1))),
          onNext: () => setState(
              () => _plannedDate = weekStart.add(const Duration(days: 7))),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 104,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: week.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = week[index];
              final count = tasks
                  .where((task) =>
                      task.dueAt != null &&
                      DateUtils.isSameDay(task.dueAt, date))
                  .length;
              return _WeekDayCard(
                date: date,
                locale: locale,
                selected: DateUtils.isSameDay(date, _plannedDate),
                isToday: DateUtils.isSameDay(date, DateTime.now()),
                count: count,
                accent: accent,
                onTap: () => setState(() => _plannedDate = date),
              );
            },
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          child: Text(
            DateFormat('EEEE d MMMM', locale == 'tr' ? 'tr_TR' : 'en_US')
                .format(_plannedDate),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    ];
    if (selected.isEmpty) {
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _PlannedEmptyCard(
              title: l10n.plannedDayEmpty,
              onAdd: () => showTaskEditorSheet(
                context,
                initialDueDate: _plannedDate,
              ),
              accent: accent,
            ),
          ),
        ),
      );
    } else {
      widgets.add(
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Padding(
              key: ValueKey(_plannedDate),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (final task in selected)
                    _plannedCard(task, lists, accent),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (upcoming.isNotEmpty) {
      widgets.add(SliverToBoxAdapter(
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
      ));
      widgets.add(_buildList(upcoming, lists, accent));
    }
    return widgets;
  }

  DateTime _weekStart(DateTime date, String locale) {
    final sundayFirst = locale != 'tr';
    final offset = sundayFirst ? date.weekday % 7 : date.weekday - 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: offset));
  }

  int _plannedTaskCompare(TodoTask a, TodoTask b) {
    final aDate = a.startAt ?? a.dueAt!;
    final bDate = b.startAt ?? b.dueAt!;
    return aDate.compareTo(bDate);
  }

  Widget _plannedCard(TodoTask task, List<TaskList> lists, Color accent) {
    final cardAccent = task.listId == null
        ? accent
        : Color(lists
            .where((list) => list.id == task.listId)
            .map((list) => list.color)
            .firstWhere((_) => true, orElse: () => accent.toARGB32()));
    final time = task.startAt == null
        ? AppLocalizations.of(context).allDay
        : DateFormat('HH:mm').format(task.startAt!);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child:
                    Text(time, style: Theme.of(context).textTheme.labelMedium),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border(left: BorderSide(color: cardAccent, width: 4)),
                ),
                child: _buildTile(task, lists, cardAccent),
              ),
            ),
          ],
        ),
      ),
    );
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

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.weekStart,
    required this.locale,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime weekStart;
  final String locale;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('d MMMM', locale == 'tr' ? 'tr_TR' : 'en_US');
    final end = weekStart.add(const Duration(days: 6));
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(
            child: Text(
              '${format.format(weekStart)} – ${format.format(end)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          IconButton(
              onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
        ],
      ),
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  const _WeekDayCard({
    required this.date,
    required this.locale,
    required this.selected,
    required this.isToday,
    required this.count,
    required this.accent,
    required this.onTap,
  });

  final DateTime date;
  final String locale;
  final bool selected;
  final bool isToday;
  final int count;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final day = DateFormat('EEE', locale == 'tr' ? 'tr_TR' : 'en_US')
        .format(date)
        .replaceAll('.', '');
    return Semantics(
      button: true,
      selected: selected,
      label: '$day ${date.day}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 62,
        decoration: BoxDecoration(
          color: selected ? accent : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: isToday && !selected
              ? Border.all(color: accent.withValues(alpha: 0.55), width: 1.5)
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        )),
                Text('${date.day}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: selected ? scheme.onPrimary : scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        )),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    count == 0 ? '—' : '$count',
                    key: ValueKey(count),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? scheme.onPrimary.withValues(alpha: 0.8)
                              : scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlannedEmptyCard extends StatelessWidget {
  const _PlannedEmptyCard({
    required this.title,
    required this.onAdd,
    required this.accent,
  });

  final String title;
  final VoidCallback onAdd;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.event_available_rounded, color: accent),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            IconButton(
              tooltip: AppLocalizations.of(context).newTask,
              onPressed: onAdd,
              icon: Icon(Icons.add_rounded, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
