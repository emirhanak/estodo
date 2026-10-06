import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/connectivity_provider.dart';
import '../../../../core/services/notification_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/preferences_provider.dart';
import '../../../../core/services/widget_data_service.dart';
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
import '../widgets/focus_mini_bar.dart';
import '../widgets/sync_status_badge.dart';
import '../utils/focus_session_controller.dart';
import 'planned_screen.dart';
import 'search_screen.dart';
import 'task_collection_screen.dart';
import '../utils/list_palette.dart';
import '../../../auth/presentation/user_display.dart';

part 'home_navigation.dart';

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
    ref.watch(widgetDataSyncProvider);

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
      // The planned tab brings its own composer button so the action can carry
      // the selected day and offer habits.
      HomeSection.completed ||
      HomeSection.search ||
      HomeSection.planned ||
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
                  Expanded(
                    child: Stack(
                      children: [
                        body,
                        const Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: FocusMiniBar(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: canAddTask ? _addTaskButton() : null,
          );
        }

        final isPlanned = _section == HomeSection.planned;
        return Scaffold(
          key: _scaffoldKey,
          // The planned tab puts the menu inside its own date header, so the
          // whole top row belongs to planning controls.
          appBar: isPlanned
              ? null
              : AppBar(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: Text(
                    _title(selectedList, AppLocalizations.of(context)),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  leading: IconButton(
                    tooltip:
                        Localizations.localeOf(context).languageCode == 'tr'
                            ? 'Menüyü aç'
                            : 'Open menu',
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  actions: const [
                    SyncStatusBadge(),
                    SizedBox(width: 8),
                  ],
                ),
          drawer: Drawer(
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: navigation,
          ),
          body: isPlanned ? SafeArea(bottom: false, child: body) : body,
          bottomNavigationBar:
              _buildMobileBottomBar(context, AppLocalizations.of(context)),
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

  Widget _buildMobileBottomBar(BuildContext context, AppLocalizations l10n) {
    final showBottomNav = switch (_section) {
      HomeSection.search || HomeSection.settings => false,
      _ => true,
    };
    final hasActiveFocus =
        ref.watch(focusTimerProvider.select((s) => s.isActive));

    if (!showBottomNav && !hasActiveFocus) {
      return const SizedBox.shrink();
    }

    final selectedIndex = switch (_section) {
      HomeSection.myDay => 0,
      HomeSection.planned => 1,
      HomeSection.important => 2,
      HomeSection.tasks => 3,
      HomeSection.customList || HomeSection.completed => 4,
      _ => 0,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FocusMiniBar(),
        if (showBottomNav)
          NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: _onBottomNavSelected,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.wb_sunny_outlined),
                selectedIcon: const Icon(Icons.wb_sunny_rounded),
                label: l10n.myDay,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month_rounded),
                label: l10n.planned,
              ),
              NavigationDestination(
                icon: const Icon(Icons.star_outline_rounded),
                selectedIcon: const Icon(Icons.star_rounded),
                label: l10n.important,
              ),
              NavigationDestination(
                icon: const Icon(Icons.check_circle_outline_rounded),
                selectedIcon: const Icon(Icons.check_circle_rounded),
                label: l10n.tasks,
              ),
              NavigationDestination(
                icon: const Icon(Icons.folder_outlined),
                selectedIcon: const Icon(Icons.folder_rounded),
                label: l10n.lists,
              ),
            ],
          ),
      ],
    );
  }

  void _onBottomNavSelected(int index) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        _selectSection(HomeSection.myDay);
      case 1:
        _selectSection(HomeSection.planned);
      case 2:
        _selectSection(HomeSection.important);
      case 3:
        _selectSection(HomeSection.tasks);
      case 4:
        _scaffoldKey.currentState?.openDrawer();
    }
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
      builder: (context) => _ListEditorDialog(
        defaultColor: ListPalette.nextDefault(
          (ref.read(listsProvider).value ?? const <TaskList>[])
              .map((list) => list.color),
        ),
      ),
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
