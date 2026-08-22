import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/task_list.dart';
import '../../domain/entities/todo_task.dart';
import '../providers/task_providers.dart';
import '../utils/planned_layout.dart';
import '../utils/calendar_import.dart';
import '../utils/planned_smart_planner.dart';
import '../widgets/empty_state.dart';
import '../widgets/planned/planned_day_timeline.dart';
import '../widgets/planned/planned_format.dart';
import '../widgets/planned/planned_header.dart';
import '../widgets/planned/planned_month_grid.dart';
import '../widgets/planned/planned_unscheduled.dart';
import '../widgets/planned/planned_week_grid.dart';
import '../widgets/planned/planned_week_strip.dart';
import '../widgets/task_editor_sheet.dart';

/// The planned tab: a Structured-style visual timeline of everything that has
/// a due date, with a day and a week view.
class PlannedScreen extends ConsumerStatefulWidget {
  const PlannedScreen({super.key});

  @override
  ConsumerState<PlannedScreen> createState() => _PlannedScreenState();
}

class _PlannedScreenState extends ConsumerState<PlannedScreen> {
  /// Two-pane (inbox + timeline) above this width, single pane below.
  static const _wideBreakpoint = 760.0;
  static const _compactBreakpoint = 460.0;

  late DateTime _selectedDate = PlannedLayout.dayOf(DateTime.now());
  late final PageController _dayController = PageController(
    initialPage: PlannedLayout.pageIndexOf(_selectedDate),
  );

  PlannedViewMode _mode = PlannedViewMode.day;
  DateTime _now = DateTime.now();
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _dayController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    final day = PlannedLayout.dayOf(date);
    if (PlannedLayout.isSameDay(day, _selectedDate)) return;
    setState(() => _selectedDate = day);
    if (_mode == PlannedViewMode.day && _dayController.hasClients) {
      final target = PlannedLayout.pageIndexOf(day);
      final current = _dayController.page?.round() ?? target;
      if (target == current) return;
      if ((target - current).abs() > 2) {
        _dayController.jumpToPage(target);
      } else {
        _dayController.animateToPage(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _changeMode(PlannedViewMode mode) {
    setState(() => _mode = mode);
    if (mode != PlannedViewMode.day) return;
    // The pager keeps the page it had before the week view took over, so
    // realign it with the day the user picked meanwhile.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dayController.hasClients) return;
      final target = PlannedLayout.pageIndexOf(_selectedDate);
      if ((_dayController.page?.round() ?? target) != target) {
        _dayController.jumpToPage(target);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) _selectDate(picked);
  }

  void _openTask(TodoTask task) => showTaskEditorSheet(context, task: task);

  void _toggleTask(TodoTask task) =>
      ref.read(taskControllerProvider).toggleComplete(task);

  void _addAt(DateTime start) => showTaskEditorSheet(
        context,
        initialDueDate: PlannedLayout.dayOf(start),
        initialStartAt: start,
      );

  Future<void> _schedule(TodoTask task, DateTime start) async {
    final due = task.dueAt;
    final aligned = DateTime(
      start.year,
      start.month,
      start.day,
      due?.hour ?? 0,
      due?.minute ?? 0,
    );
    await ref.read(taskControllerProvider).updateTask(
          task.copyWith(startAt: start, dueAt: aligned),
        );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.plannedScheduledAt(PlannedFormat.time(start))),
      ),
    );
  }

  Future<void> _smartPlan(PlannedDay day) async {
    final l10n = AppLocalizations.of(context);
    final assignments = PlannedSmartPlanner.plan(day, now: _now);
    if (assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plannedNothingToPlan)),
      );
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.auto_awesome_rounded),
        title: Text(l10n.plannedSmartPlan),
        content: Text(l10n.plannedSmartPlanConfirm(assignments.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.plannedApplyPlan),
          ),
        ],
      ),
    );
    if (approved != true) return;
    for (final assignment in assignments) {
      final start = assignment.start;
      await ref.read(taskControllerProvider).updateTask(
            assignment.task.copyWith(
              startAt: start,
              dueAt: PlannedLayout.dayOf(start),
            ),
          );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.plannedSmartPlanDone(assignments.length))),
    );
  }

  Future<void> _importCalendar() async {
    final l10n = AppLocalizations.of(context);
    try {
      final file = await FilePicker.pickFile();
      if (file == null || !mounted) return;
      if (!file.name.toLowerCase().endsWith('.ics')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.plannedImportInvalid)),
        );
        return;
      }
      final events = CalendarImport.parseBytes(await file.readAsBytes());
      if (!mounted) return;
      if (events.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.plannedImportEmpty)),
        );
        return;
      }
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.calendar_month_rounded),
          title: Text(l10n.plannedImportCalendar),
          content: Text(l10n.plannedImportConfirm(events.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.plannedImport),
            ),
          ],
        ),
      );
      if (approved != true) return;
      for (final event in events) {
        await ref.read(taskControllerProvider).createTask(
              title: event.title,
              notes: event.notes,
              dueAt: event.dueAt,
              startAt: event.startAt,
              durationMinutes: event.durationMinutes,
            );
      }
      if (!mounted) return;
      _selectDate(events.first.dueAt);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plannedImportDone(events.length))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plannedImportFailed)),
      );
    }
  }

  void _handleAction(PlannedHeaderAction action, PlannedDay day) {
    switch (action) {
      case PlannedHeaderAction.smartPlan:
        unawaited(_smartPlan(day));
        return;
      case PlannedHeaderAction.importCalendar:
        unawaited(_importCalendar());
        return;
    }
  }

  PlannedDay _dayFor(
    DateTime date,
    List<TodoTask> tasks,
    List<TaskList> lists,
    Color accent,
  ) {
    return PlannedLayout.buildDay(
      date: date,
      tasks: tasks,
      lists: lists,
      fallback: accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final tasksAsync = ref.watch(tasksProvider);
    final lists = ref.watch(listsProvider).value ?? const <TaskList>[];

    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) {
          final l10n = AppLocalizations.of(context);
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: l10n.errorCouldNotLoadTasks,
            message: l10n.errorTryAgain,
          );
        },
        data: (tasks) {
          final dated = tasks.where((task) => task.dueAt != null).toList();
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= _wideBreakpoint;
              final compact = constraints.maxWidth < _compactBreakpoint;
              final selectedDay = _dayFor(_selectedDate, dated, lists, accent);

              final main = _mainColumn(
                tasks: dated,
                lists: lists,
                accent: accent,
                selectedDay: selectedDay,
                compact: compact,
                wide: wide,
              );

              if (!wide) return main;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: constraints.maxWidth >= 1000 ? 320 : 280,
                    child: PlannedInboxPanel(
                      day: selectedDay,
                      accent: accent,
                      onOpen: _openTask,
                      onToggle: _toggleTask,
                      onSchedule: (task) => _schedule(
                        task,
                        PlannedLayout.nextFreeSlot(
                          selectedDay,
                          minutes: task.durationMinutes ??
                              PlannedLayout.defaultDurationMinutes,
                          now: _now,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: main),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _mainColumn({
    required List<TodoTask> tasks,
    required List<TaskList> lists,
    required Color accent,
    required PlannedDay selectedDay,
    required bool compact,
    required bool wide,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlannedHeader(
          date: _selectedDate,
          mode: _mode,
          accent: accent,
          compact: compact,
          onModeChanged: _changeMode,
          onPickDate: _pickDate,
          onToday: () => _selectDate(DateTime.now()),
          onAction: (action) => _handleAction(action, selectedDay),
        ),
        _SummaryLine(day: selectedDay, accent: accent, compact: compact),
        if (_mode != PlannedViewMode.month)
          PlannedWeekStrip(
            selectedDate: _selectedDate,
            tasks: tasks,
            lists: lists,
            accent: accent,
            compact: compact,
            onSelect: _selectDate,
          ),
        const SizedBox(height: 6),
        Expanded(
          child: _Sheet(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: switch (_mode) {
                PlannedViewMode.day => _dayPager(tasks, lists, accent, wide),
                PlannedViewMode.week => _weekView(tasks, lists, accent),
                PlannedViewMode.month => PlannedMonthGrid(
                    key: ValueKey(
                        'planned-month-${_selectedDate.year}-${_selectedDate.month}'),
                    month: _selectedDate,
                    selectedDate: _selectedDate,
                    tasks: tasks,
                    lists: lists,
                    accent: accent,
                    onSelectDay: _selectDate,
                  ),
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayPager(
    List<TodoTask> tasks,
    List<TaskList> lists,
    Color accent,
    bool wide,
  ) {
    return PageView.builder(
      key: const ValueKey('planned-day-pager'),
      controller: _dayController,
      onPageChanged: (page) {
        final date = PlannedLayout.dateOfPage(page);
        if (!PlannedLayout.isSameDay(date, _selectedDate)) {
          setState(() => _selectedDate = date);
        }
      },
      itemBuilder: (context, page) {
        final date = PlannedLayout.dateOfPage(page);
        final day = _dayFor(date, tasks, lists, accent);
        return PlannedDayTimeline(
          key: ValueKey('planned-day-$page'),
          day: day,
          now: _now,
          accent: accent,
          showUnscheduled: !wide,
          horizontalPadding: wide ? 18 : 12,
          maxContentWidth: wide ? 880 : double.infinity,
          onOpen: _openTask,
          onToggle: _toggleTask,
          onAddAt: _addAt,
          onSchedule: _schedule,
        );
      },
    );
  }

  Widget _weekView(
    List<TodoTask> tasks,
    List<TaskList> lists,
    Color accent,
  ) {
    final start = PlannedLayout.weekStart(
      _selectedDate,
      mondayFirst: PlannedFormat.mondayFirst(context),
    );
    final days = [
      for (final date in PlannedLayout.weekDays(start))
        _dayFor(date, tasks, lists, accent),
    ];
    return PlannedWeekGrid(
      key: ValueKey('planned-week-${start.toIso8601String()}'),
      days: days,
      selectedDate: _selectedDate,
      now: _now,
      accent: accent,
      onOpen: _openTask,
      onAddAt: _addAt,
      onSelectDay: _selectDate,
      onSchedule: _schedule,
    );
  }
}

/// Rounded panel the timeline lives in, echoing Structured's sheet.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// `2 of 5 done · 3 h 30 min` progress line under the headline.
class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.day,
    required this.accent,
    required this.compact,
  });

  final PlannedDay day;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (day.totalCount == 0) {
      return const SizedBox(height: 10);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 24 : 30, 0, compact ? 18 : 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${l10n.plannedProgressSummary(day.doneCount, day.totalCount)}'
              '${day.plannedMinutes > 0 ? ' · ${PlannedFormat.duration(l10n, day.plannedMinutes)}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: day.progress),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: scheme.outlineVariant.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
