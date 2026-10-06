import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/services/preferences_provider.dart';
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
import '../widgets/planned/composer/planned_composer.dart';
import '../utils/planned_draft.dart';
import '../utils/streak_calculator.dart';

part 'planned_screen_parts.dart';

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

  void _openTask(TodoTask task) =>
      unawaited(_composeAndFollow(showPlannedComposer(context, task: task)));

  void _toggleTask(TodoTask task) =>
      ref.read(taskControllerProvider).toggleComplete(task);

  void _addAt(DateTime start, {PlannedDraftKind? kind}) => unawaited(
        _composeAndFollow(
          showPlannedComposer(
            context,
            date: PlannedLayout.dayOf(start),
            startAt: start,
            kind: kind ?? PlannedDraftKind.habit,
          ),
        ),
      );

  /// When an entry is saved on another day, jump there and say so, so the
  /// new entry never seems to vanish.
  Future<void> _composeAndFollow(Future<DateTime?> composer) async {
    final savedDay = await composer;
    if (savedDay == null || !mounted) return;
    if (PlannedLayout.isSameDay(savedDay, _selectedDate)) return;
    _selectDate(savedDay);
    final l10n = AppLocalizations.of(context);
    final locale = PlannedFormat.intlLocale(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            l10n.plannedSavedOn(PlannedFormat.fullDay(savedDay, locale)),
          ),
        ),
      );
  }

  /// Opens the composer for the selected day, at the next sensible slot.
  void _compose({PlannedDraftKind kind = PlannedDraftKind.habit}) {
    final now = DateTime.now();
    final start = PlannedLayout.isSameDay(_selectedDate, now)
        ? PlannedLayout.roundToQuarter(now)
        : PlannedLayout.dayOf(_selectedDate).add(const Duration(hours: 9));
    _addAt(start, kind: kind);
  }

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
    final scheme = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.importCalendarTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.amber),
                ),
                title: Text(l10n.importCalendarSample),
                subtitle: Text(
                  Localizations.localeOf(context).languageCode == 'tr'
                      ? 'Seçili gün için 5 örnek Structured tarzı blok ekler'
                      : 'Adds 5 Structured-style sample blocks for the day',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _seedSampleEvents(_selectedDate);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.file_upload_outlined, color: scheme.primary),
                ),
                title: Text(l10n.importCalendarFile),
                subtitle:
                    const Text('Google Calendar, Apple iCal, Outlook (.ics)'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _importIcsFile();
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.content_paste_rounded,
                      color: Colors.teal),
                ),
                title: Text(l10n.importCalendarPaste),
                subtitle: Text(
                  Localizations.localeOf(context).languageCode == 'tr'
                      ? 'iCal (.ics) metnini doğrudan yapıştırın'
                      : 'Paste raw iCal (.ics) text directly',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pasteCalendarText();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seedSampleEvents(DateTime day) async {
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final targetDay = DateTime(day.year, day.month, day.day);

    final samples = [
      (
        title: isTr ? 'Güne Başlangıç & Günlük Plan' : 'Morning Kickoff & Plan',
        startHour: 9,
        startMin: 0,
        dur: 30,
        icon: 'wb_sunny',
        notes: isTr
            ? 'Günün önceliklerini gözden geçir.'
            : 'Review daily priorities.',
      ),
      (
        title: isTr ? 'Derin Odaklanma Seansı' : 'Deep Work Session',
        startHour: 10,
        startMin: 0,
        dur: 90,
        icon: 'laptop',
        notes: isTr
            ? 'Önemli projedeki kritik görevi tamamla.'
            : 'Focus on the most critical project task.',
      ),
      (
        title: isTr ? 'Öğle Molası & Kısa Yürüyüş' : 'Lunch & Short Walk',
        startHour: 12,
        startMin: 30,
        dur: 45,
        icon: 'restaurant',
        notes: isTr ? 'Mola ver, zihnini tazele.' : 'Take a break and refresh.',
      ),
      (
        title: isTr ? 'Ekip Senkronizasyon Toplantısı' : 'Team Sync Meeting',
        startHour: 14,
        startMin: 0,
        dur: 45,
        icon: 'people',
        notes: isTr
            ? 'İlerlemeyi paylaş ve engelleri değerlendir.'
            : 'Sync on progress and blockers.',
      ),
      (
        title:
            isTr ? 'Günün Değerlendirmesi & Kapanış' : 'Day Wrap-up & Review',
        startHour: 17,
        startMin: 0,
        dur: 30,
        icon: 'check',
        notes: isTr
            ? 'Tamamlananları işaretle, yarını hazırla.'
            : 'Check off completed items and prep for tomorrow.',
      ),
    ];

    for (final s in samples) {
      final start =
          targetDay.add(Duration(hours: s.startHour, minutes: s.startMin));
      await ref.read(taskControllerProvider).createTask(
            title: s.title,
            notes: s.notes,
            iconKey: s.icon,
            dueAt: targetDay,
            startAt: start,
            durationMinutes: s.dur,
          );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.calendarImportSuccess(samples.length))),
    );
  }

  Future<void> _importIcsFile() async {
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
      await _processParsedEvents(events);
    } catch (error) {
      debugPrint('Calendar import failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plannedImportFailed)),
      );
    }
  }

  Future<void> _pasteCalendarText() async {
    final l10n = AppLocalizations.of(context);
    final textController = TextEditingController();
    final source = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.importCalendarPaste),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: textController,
            maxLines: 8,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'BEGIN:VCALENDAR\n...\nEND:VCALENDAR',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, textController.text.trim()),
            child: Text(l10n.plannedImport),
          ),
        ],
      ),
    );
    textController.dispose();
    if (source != null && source.isNotEmpty) {
      final events = CalendarImport.parse(source);
      await _processParsedEvents(events);
    }
  }

  Future<void> _processParsedEvents(List<CalendarImportEvent> events) async {
    final l10n = AppLocalizations.of(context);
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
      SnackBar(content: Text(l10n.calendarImportSuccess(events.length))),
    );
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

    return Stack(
      children: [
        Container(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          child: _body(tasksAsync, lists, accent),
        ),
        Positioned(
          right: 20,
          bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
          child: _ComposerButton(
            accent: accent,
            onTask: () => _compose(kind: PlannedDraftKind.task),
            onHabit: () => _compose(kind: PlannedDraftKind.habit),
          ),
        ),
      ],
    );
  }

  Widget _body(
    AsyncValue<List<TodoTask>> tasksAsync,
    List<TaskList> lists,
    Color accent,
  ) {
    return tasksAsync.when(
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
    final canShowWeek = _mode != PlannedViewMode.month;
    final weekExpanded = ref.watch(plannedWeekStripExpandedProvider);
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
          weekExpanded: weekExpanded,
          onToggleWeek: canShowWeek
              ? () =>
                  ref.read(plannedWeekStripExpandedProvider.notifier).toggle()
              : null,
        ),
        _SummaryLine(day: selectedDay, accent: accent, compact: compact),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          reverseDuration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.12),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
          ),
          child: canShowWeek && weekExpanded
              ? PlannedWeekStrip(
                  key: const ValueKey('planned-week-strip'),
                  selectedDate: _selectedDate,
                  tasks: tasks,
                  lists: lists,
                  accent: accent,
                  compact: compact,
                  onSelect: _selectDate,
                )
              : const SizedBox(
                  key: ValueKey('planned-week-strip-hidden'),
                  width: double.infinity,
                ),
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
          horizontalPadding: wide ? 18 : 8,
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
