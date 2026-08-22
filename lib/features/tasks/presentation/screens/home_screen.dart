import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/connectivity_provider.dart';
import '../../../../core/services/notification_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/preferences_provider.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/entities/list_sort_option.dart';
import '../../domain/entities/task_list.dart';
import '../../domain/entities/todo_task.dart';
import '../providers/selection_provider.dart';
import '../providers/task_providers.dart';
import '../widgets/quick_add_field.dart';
import '../widgets/task_editor_sheet.dart';
import 'planned_screen.dart';
import 'search_screen.dart';
import 'task_collection_screen.dart';

enum HomeSection {
  myDay,
  important,
  planned,
  tasks,
  completed,
  search,
  settings,
  customList,
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  var _section = HomeSection.myDay;
  String? _selectedListId;
  bool _wideMenuOpen = true;
  StreamSubscription<String>? _notificationTapSub;
  StreamSubscription<NotificationAction>? _notificationActionSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(notificationServiceProvider);
      _notificationTapSub = service.onNotificationTap.listen(_openTaskById);
      _notificationActionSub =
          service.onNotificationAction.listen(_handleNotificationAction);
    });
  }

  @override
  void dispose() {
    _notificationTapSub?.cancel();
    _notificationActionSub?.cancel();
    super.dispose();
  }

  Future<void> _handleNotificationAction(NotificationAction action) async {
    final tasks = ref.read(tasksProvider).value;
    TodoTask? task;
    for (final candidate in tasks ?? const <TodoTask>[]) {
      if (candidate.id == action.taskId) {
        task = candidate;
        break;
      }
    }
    if (task == null || !mounted) return;
    final controller = ref.read(taskControllerProvider);
    switch (action.actionId) {
      case 'complete':
        await controller.toggleComplete(task);
      case 'snooze_10m':
        await controller.snoozeTask(task, const Duration(minutes: 10));
    }
  }

  Future<void> _openTaskById(String taskId) async {
    final tasks = ref.read(tasksProvider).value;
    if (tasks == null) return;
    TodoTask? found;
    for (final t in tasks) {
      if (t.id == taskId) {
        found = t;
        break;
      }
    }
    if (found != null && mounted) {
      showTaskEditorSheet(context, task: found);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(myDayCarryOverProvider).whenOrNull(error: (_, __) {});
    ref.watch(deviceTokenRegistrationProvider);

    final lists = ref.watch(listsProvider).value ?? const <TaskList>[];
    final tasks = ref.watch(tasksProvider).value ?? const <TodoTask>[];
    TaskList? selectedList;
    for (final list in lists) {
      if (list.id == _selectedListId) {
        selectedList = list;
        break;
      }
    }
    final body = _ConnectivityFrame(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: RepaintBoundary(
          key: ValueKey('${_section.name}-${_selectedListId ?? ''}'),
          child: _buildBody(selectedList),
        ),
      ),
    );
    final canAddTask = switch (_section) {
      HomeSection.completed ||
      HomeSection.search ||
      HomeSection.settings =>
        false,
      _ => true,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final navigationWidth = constraints.maxWidth < 900 ? 264.0 : 296.0;
        final navigation = _SideNavigation(
          section: _section,
          selectedListId: _selectedListId,
          lists: lists,
          tasks: tasks,
          onSelectSection: _selectSection,
          onSelectList: _selectList,
          onCreateList: _createList,
          onRenameList: _renameList,
          onDeleteList: _deleteList,
        );

        if (wide) {
          final navigationColor = Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.4);
          return Scaffold(
            // Keep the existing surface palette while letting content reach
            // the iPad home-indicator edge.
            body: SafeArea(
              top: true,
              bottom: false,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: _wideMenuOpen ? navigationWidth : 78,
                    decoration: BoxDecoration(
                      color: navigationColor,
                    ),
                    child: _SideNavigation(
                      section: _section,
                      selectedListId: _selectedListId,
                      lists: lists,
                      tasks: tasks,
                      compact: !_wideMenuOpen,
                      onToggleCompact: () =>
                          setState(() => _wideMenuOpen = !_wideMenuOpen),
                      onSelectSection: _selectSection,
                      onSelectList: _selectList,
                      onCreateList: _createList,
                      onRenameList: _renameList,
                      onDeleteList: _deleteList,
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
            floatingActionButton: canAddTask ? _addTaskButton() : null,
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            // The planned tab carries its own Structured-style date headline,
            // so the app bar only keeps the menu affordance there.
            toolbarHeight: _section == HomeSection.planned ? 48 : null,
            title: _section == HomeSection.planned
                ? null
                : Text(
                    _title(selectedList, AppLocalizations.of(context)),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
            leading: IconButton(
              tooltip: Localizations.localeOf(context).languageCode == 'tr'
                  ? 'Menüyü aç'
                  : 'Open menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          drawer: Drawer(
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: navigation,
          ),
          body: body,
          floatingActionButton: canAddTask ? _addTaskButton() : null,
        );
      },
    );
  }

  Widget _buildBody(TaskList? selectedList) {
    final l10n = AppLocalizations.of(context);
    final todayKey = DateTimeFormatter.todayKey();
    return switch (_section) {
      HomeSection.myDay => TaskCollectionScreen(
          title: l10n.myDay,
          subtitle: DateTimeFormatter.fullDayLabel(
            DateTime.now(),
            locale: Localizations.localeOf(context).languageCode,
          ),
          icon: Icons.wb_sunny_outlined,
          emptyTitle: l10n.emptyMyDayTitle,
          emptyMessage: l10n.emptyMyDayBody,
          filter: (task) => !task.isCompleted && task.isInMyDay(todayKey),
          showSuggestions: true,
          showMyDayBanner: true,
          quickAddPrefill: const QuickAddPrefill(isMyDay: true),
        ),
      HomeSection.important => TaskCollectionScreen(
          title: l10n.important,
          icon: Icons.star_border_rounded,
          emptyTitle: l10n.emptyImportantTitle,
          emptyMessage: l10n.emptyImportantBody,
          filter: (task) => task.isImportant,
          quickAddPrefill: const QuickAddPrefill(isImportant: true),
        ),
      HomeSection.planned => const PlannedScreen(),
      HomeSection.tasks => TaskCollectionScreen(
          title: l10n.tasks,
          icon: Icons.inbox_rounded,
          emptyTitle: l10n.emptyTasksTitle,
          emptyMessage: l10n.emptyTasksBody,
          filter: (task) => task.listId == null,
          quickAddPrefill: const QuickAddPrefill(),
        ),
      HomeSection.completed => TaskCollectionScreen(
          title: l10n.completed,
          icon: Icons.check_circle_outline_rounded,
          emptyTitle: l10n.emptyCompletedTitle,
          emptyMessage: l10n.emptyCompletedBody,
          filter: (task) => task.isCompleted,
          layout: CollectionLayout.completedArchive,
          showQuickAdd: false,
        ),
      HomeSection.search => SearchScreen(onOpenList: _selectList),
      HomeSection.settings => const SettingsScreen(),
      HomeSection.customList => selectedList == null
          ? TaskCollectionScreen(
              title: l10n.list,
              icon: Icons.list_rounded,
              emptyTitle: l10n.listUnavailable,
              emptyMessage: l10n.selectAnotherList,
              filter: (_) => false,
            )
          : _CustomListScreen(list: selectedList),
    };
  }

  FloatingActionButton _addTaskButton() {
    return FloatingActionButton(
      onPressed: () {
        showTaskEditorSheet(
          context,
          initialListId:
              _section == HomeSection.customList ? _selectedListId : null,
          initialMyDay: _section == HomeSection.myDay,
          initialImportant: _section == HomeSection.important,
        );
      },
      child: const Icon(Icons.add_rounded),
    );
  }

  String _title(TaskList? selectedList, AppLocalizations l10n) {
    return switch (_section) {
      HomeSection.myDay => l10n.myDay,
      HomeSection.important => l10n.important,
      HomeSection.planned => l10n.planned,
      HomeSection.tasks => l10n.tasks,
      HomeSection.completed => l10n.completed,
      HomeSection.search => l10n.search,
      HomeSection.settings => l10n.settings,
      HomeSection.customList => selectedList?.name ?? l10n.list,
    };
  }

  void _selectSection(HomeSection section) {
    ref.read(taskSelectionProvider.notifier).clear();
    setState(() {
      _section = section;
      if (section != HomeSection.customList) {
        _selectedListId = null;
      }
    });
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _selectList(TaskList list) {
    ref.read(taskSelectionProvider.notifier).clear();
    setState(() {
      _section = HomeSection.customList;
      _selectedListId = list.id;
    });
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _createList() async {
    _scaffoldKey.currentState?.closeDrawer();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final draft = await showDialog<_ListDraft>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black54,
      builder: (context) => const _ListEditorDialog(),
    );
    if (!mounted) return;
    if (draft == null) return;
    final list = await ref
        .read(taskControllerProvider)
        .createList(draft.name, draft.color);
    _selectList(list);
  }

  Future<void> _renameList(TaskList list) async {
    _scaffoldKey.currentState?.closeDrawer();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final draft = await showDialog<_ListDraft>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black54,
      builder: (context) => _ListEditorDialog(existing: list),
    );
    if (!mounted) return;
    if (draft == null) return;
    await ref.read(taskControllerProvider).updateList(
          list.copyWith(name: draft.name, color: draft.color),
        );
  }

  Future<void> _deleteList(TaskList list) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteListConfirmTitle),
        content: Text(l10n.deleteListConfirmBody(list.name)),
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

    await ref.read(taskControllerProvider).deleteList(list);
    if (_selectedListId == list.id) {
      _selectSection(HomeSection.tasks);
    }
  }
}

class _CustomListScreen extends ConsumerWidget {
  const _CustomListScreen({required this.list});

  final TaskList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return TaskCollectionScreen(
      title: list.name,
      icon: Icons.format_list_bulleted_rounded,
      emptyTitle: l10n.emptyListTitle,
      emptyMessage: l10n.emptyListBody,
      filter: (task) => task.listId == list.id,
      list: list,
      quickAddPrefill: QuickAddPrefill(listId: list.id),
      headerActions: [_SortMenuButton(list: list)],
    );
  }
}

class _SortMenuButton extends ConsumerWidget {
  const _SortMenuButton({required this.list});

  final TaskList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<ListSortOption>(
      tooltip: l10n.sortBy,
      icon: const Icon(Icons.sort_rounded),
      onSelected: (option) async {
        final ascending =
            option == list.sortOption ? !list.sortAscending : true;
        await ref.read(taskControllerProvider).changeListSort(
              list,
              option: option,
              ascending: ascending,
            );
      },
      itemBuilder: (context) => [
        for (final option in ListSortOption.values)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                if (option == list.sortOption)
                  Icon(
                    list.sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 16,
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(_sortLabel(option, l10n)),
              ],
            ),
          ),
      ],
    );
  }

  String _sortLabel(ListSortOption option, AppLocalizations l10n) {
    return switch (option) {
      ListSortOption.manual => l10n.sortManual,
      ListSortOption.importance => l10n.sortImportance,
      ListSortOption.dueDate => l10n.sortDueDate,
      ListSortOption.alphabetical => l10n.sortAlphabetical,
      ListSortOption.creationDate => l10n.sortCreationDate,
      ListSortOption.myDay => l10n.sortMyDay,
    };
  }
}

class _ConnectivityFrame extends ConsumerWidget {
  const _ConnectivityFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(onlineStatusProvider).value ?? true;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: isOnline
              ? const SizedBox.shrink()
              : Material(
                  key: const ValueKey('offline'),
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.wifi_off_rounded),
                    title: Text(
                      l10n.offlineBanner,
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SideNavigation extends ConsumerWidget {
  const _SideNavigation({
    required this.section,
    required this.selectedListId,
    required this.lists,
    required this.tasks,
    required this.onSelectSection,
    required this.onSelectList,
    required this.onCreateList,
    required this.onRenameList,
    required this.onDeleteList,
    this.compact = false,
    this.onToggleCompact,
  });

  final HomeSection section;
  final String? selectedListId;
  final List<TaskList> lists;
  final List<TodoTask> tasks;
  final ValueChanged<HomeSection> onSelectSection;
  final ValueChanged<TaskList> onSelectList;
  final VoidCallback onCreateList;
  final ValueChanged<TaskList> onRenameList;
  final ValueChanged<TaskList> onDeleteList;
  final bool compact;
  final VoidCallback? onToggleCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final hidden = ref.watch(hiddenSmartListsProvider);
    final todayKey = DateTimeFormatter.todayKey();
    final counts = <HomeSection, int>{
      HomeSection.myDay: tasks
          .where((task) => !task.isCompleted && task.isInMyDay(todayKey))
          .length,
      HomeSection.important:
          tasks.where((task) => !task.isCompleted && task.isImportant).length,
      HomeSection.planned:
          tasks.where((task) => !task.isCompleted && task.dueAt != null).length,
      HomeSection.tasks: tasks
          .where((task) => !task.isCompleted && task.listId == null)
          .length,
      HomeSection.completed: tasks.where((task) => task.isCompleted).length,
    };

    final sortedLists = List<TaskList>.from(lists)
      ..sort((a, b) {
        final p = a.position.compareTo(b.position);
        if (p != 0) return p;
        return a.createdAt.compareTo(b.createdAt);
      });

    Widget smartTile({
      required HomeSection target,
      required IconData icon,
      required String label,
      required String prefKey,
      bool compact = false,
    }) {
      if (hidden.contains(prefKey)) return const SizedBox.shrink();
      return _NavTile(
        icon: icon,
        label: label,
        count: counts[target] ?? 0,
        selected: section == target,
        onTap: () => onSelectSection(target),
        compact: compact,
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: compact ? 'Menüyü aç' : 'Menüyü kapat',
                  onPressed: onToggleCompact,
                  icon: Icon(
                      compact ? Icons.menu_rounded : Icons.menu_open_rounded),
                ),
                if (!compact)
                  Expanded(
                    child: SvgPicture.asset(
                      'assets/branding/estodo_wordmark.svg',
                      height: 32,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      placeholderBuilder: (_) => Text(
                        'estodo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (user != null && !compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Text(
                user.displayName ?? user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Material(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelectSection(HomeSection.search),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: scheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 10),
                      if (!compact)
                        Text(l10n.search,
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate([
                    smartTile(
                      target: HomeSection.myDay,
                      icon: Icons.wb_sunny_outlined,
                      label: l10n.myDay,
                      compact: compact,
                      prefKey: 'myDay',
                    ),
                    smartTile(
                      target: HomeSection.important,
                      icon: Icons.star_border_rounded,
                      label: l10n.important,
                      compact: compact,
                      prefKey: 'important',
                    ),
                    smartTile(
                      target: HomeSection.planned,
                      icon: Icons.event_outlined,
                      label: l10n.planned,
                      compact: compact,
                      prefKey: 'planned',
                    ),
                    smartTile(
                      target: HomeSection.tasks,
                      icon: Icons.inbox_outlined,
                      label: l10n.tasks,
                      compact: compact,
                      prefKey: 'tasks',
                    ),
                    smartTile(
                      target: HomeSection.completed,
                      icon: Icons.check_circle_outline_rounded,
                      label: l10n.completed,
                      compact: compact,
                      prefKey: 'completed',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      child: Divider(
                          color: scheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                  ]),
                ),
                SliverReorderableList(
                  itemCount: sortedLists.length,
                  // ignore: deprecated_member_use
                  onReorder: (oldIndex, newIndex) async {
                    final mutable = List<TaskList>.from(sortedLists);
                    final ix = newIndex > oldIndex ? newIndex - 1 : newIndex;
                    final moved = mutable.removeAt(oldIndex);
                    mutable.insert(ix, moved);
                    await ref
                        .read(taskControllerProvider)
                        .reorderLists(mutable);
                  },
                  itemBuilder: (context, index) {
                    final list = sortedLists[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey('reorder-list-${list.id}'),
                      index: index,
                      child: _CustomListTile(
                        list: list,
                        count: tasks
                            .where((task) =>
                                !task.isCompleted && task.listId == list.id)
                            .length,
                        selected: section == HomeSection.customList &&
                            selectedListId == list.id,
                        onTap: () => onSelectList(list),
                        onRename: () => onRenameList(list),
                        onDelete: () => onDeleteList(list),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: compact ? null : Text(l10n.newList),
            onTap: onCreateList,
          ),
          _NavTile(
            icon: Icons.settings_outlined,
            label: l10n.settings,
            selected: section == HomeSection.settings,
            onTap: () => onSelectSection(HomeSection.settings),
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
        selected: selected,
        leading: Icon(icon, size: 20),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: compact
              ? const SizedBox.shrink()
              : Text(label, key: ValueKey(label)),
        ),
        trailing: count == null || count == 0
            ? null
            : Text(
                count.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}

class _CustomListTile extends StatelessWidget {
  const _CustomListTile({
    required this.list,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final TaskList list;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        selected: selected,
        leading: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Color(list.color),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(list.name, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  count.toString(),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            PopupMenuButton<_ListAction>(
              tooltip: Localizations.localeOf(context).languageCode == 'tr'
                  ? 'Liste işlemleri'
                  : 'List actions',
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_horiz_rounded, size: 18),
              onSelected: (action) {
                switch (action) {
                  case _ListAction.rename:
                    onRename();
                  case _ListAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (context) {
                final l10n = AppLocalizations.of(context);
                return [
                  PopupMenuItem(
                    value: _ListAction.rename,
                    child: ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(l10n.renameList),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ListAction.delete,
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline_rounded),
                      title: Text(l10n.deleteList),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

enum _ListAction { rename, delete }

class _ListEditorDialog extends StatefulWidget {
  const _ListEditorDialog({this.existing});

  final TaskList? existing;

  @override
  State<_ListEditorDialog> createState() => _ListEditorDialogState();
}

class _ListEditorDialogState extends State<_ListEditorDialog> {
  final _controller = TextEditingController();
  late int _color;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _color = _palette.first;
    if (existing != null) {
      _controller.text = existing.name;
      _color = existing.color;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _palette = <int>[
    0xFF8E8CD8,
    0xFF5B5FC7,
    0xFF0078D4,
    0xFF00B7C3,
    0xFF107C10,
    0xFFFFB900,
    0xFFD83B01,
    0xFFE3008C,
    0xFFC239B3,
    0xFF8764B8,
    0xFFAF8B6B,
    0xFF69797E,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.existing == null ? l10n.newList : l10n.renameList),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.listName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in _palette)
                GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(color),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        width: _color == color ? 3 : 0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(_ListDraft(name: name, color: _color));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _ListDraft {
  const _ListDraft({required this.name, required this.color});

  final String name;
  final int color;
}
