import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/planned/planned_month_dropdown.dart';
import '../widgets/planned/planned_unscheduled.dart';
import '../widgets/planned/planned_week_overview.dart';
import '../widgets/planned/planned_week_strip.dart';
import '../widgets/planned/composer/planned_composer.dart';
import '../utils/planned_draft.dart';

part 'planned_screen_parts.dart';

/// Holds the currently selected date in the Planned tab so the global
/// bottom-right `+` button in [HomeScreen] can open the composer on that day.
class SelectedPlannedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => PlannedLayout.dayOf(DateTime.now());

  void select(DateTime date) {
    final day = PlannedLayout.dayOf(date);
    if (!PlannedLayout.isSameDay(state, day)) {
      state = day;
    }
  }
}

final selectedPlannedDateProvider =
    NotifierProvider<SelectedPlannedDateNotifier, DateTime>(
  SelectedPlannedDateNotifier.new,
);

/// The planned tab: a Structured-style visual timeline of everything that has
/// a due date, with a day timeline and a pull-down week overview.
class PlannedScreen extends ConsumerStatefulWidget {
  const PlannedScreen({
    super.key,
    this.showFloatingComposerButton = true,
  });

  /// Whether to render the internal floating `+` button. False on mobile
  /// [HomeScreen] where the Structured-style bottom bar provides the large
  /// bottom-right `+` button.
  final bool showFloatingComposerButton;

  @override
  ConsumerState<PlannedScreen> createState() => _PlannedScreenState();
}

class _PlannedScreenState extends ConsumerState<PlannedScreen>
    with SingleTickerProviderStateMixin {
  /// Two-pane (inbox + timeline) above this width, single pane below.
  static const _wideBreakpoint = 760.0;
  static const _compactBreakpoint = 460.0;

  late DateTime _selectedDate = PlannedLayout.dayOf(DateTime.now());
  late final PageController _dayController = PageController(
    initialPage: PlannedLayout.pageIndexOf(_selectedDate),
  );

  /// `0.0` = Day timeline sheet expanded up (Screenshot 3).
  /// `1.0` = Sheet pulled down to reveal [PlannedWeekOverview] (Screenshot 2).
  late final AnimationController _sheetController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 0.0,
  );

  bool _calendarOpen = false;
  DateTime _now = DateTime.now();
  Timer? _clock;

  bool get _isWeekOverview => _sheetController.value > 0.5;

  PlannedViewMode get _viewMode {
    if (_calendarOpen) return PlannedViewMode.month;
    if (_isWeekOverview) return PlannedViewMode.week;
    return PlannedViewMode.day;
  }

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(selectedPlannedDateProvider.notifier).select(_selectedDate);
      }
    });
    _clock = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _sheetController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    final day = PlannedLayout.dayOf(date);
    ref.read(selectedPlannedDateProvider.notifier).select(day);
    if (PlannedLayout.isSameDay(day, _selectedDate)) return;
    setState(() => _selectedDate = day);
    if (_dayController.hasClients) {
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

  void _setViewMode(PlannedViewMode mode) {
    switch (mode) {
      case PlannedViewMode.day:
        if (_calendarOpen) setState(() => _calendarOpen = false);
        _animateSheetTo(0.0);
      case PlannedViewMode.week:
        if (_calendarOpen) setState(() => _calendarOpen = false);
        _animateSheetTo(1.0);
      case PlannedViewMode.month:
        setState(() => _calendarOpen = !_calendarOpen);
    }
  }

  void _animateSheetTo(double target) {
    HapticFeedback.selectionClick();
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleSheetPosition() {
    if (_calendarOpen) {
      setState(() => _calendarOpen = false);
    }
    _animateSheetTo(_isWeekOverview ? 0.0 : 1.0);
  }

  void _onSheetDragUpdate(DragUpdateDetails details, double travelDistance) {
    if (travelDistance <= 0) return;
    final delta = (details.primaryDelta ?? 0) / travelDistance;
    _sheetController.value = (_sheetController.value + delta).clamp(0.0, 1.0);
  }

  void _onSheetDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 280) {
      _animateSheetTo(1.0);
    } else if (velocity < -280) {
      _animateSheetTo(0.0);
    } else if (_sheetController.value > 0.45) {
      _animateSheetTo(1.0);
    } else {
      _animateSheetTo(0.0);
    }
  }

  /// Picking a day in the month calendar jumps there and folds it away.
  void _pickFromCalendar(DateTime day) {
    setState(() => _calendarOpen = false);
    _selectDate(day);
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

    ref.listen<DateTime>(selectedPlannedDateProvider, (prev, next) {
      if (!PlannedLayout.isSameDay(next, _selectedDate)) {
        _selectDate(next);
      }
    });

    return Stack(
      children: [
        Container(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          child: _body(tasksAsync, lists, accent),
        ),
        if (widget.showFloatingComposerButton)
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
    final t = _sheetController.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlannedHeader(
          date: _selectedDate,
          accent: accent,
          compact: compact,
          onToday: () => _selectDate(DateTime.now()),
          onAction: (action) => _handleAction(action, selectedDay),
          calendarOpen: _calendarOpen,
          onToggleCalendar: () =>
              setState(() => _calendarOpen = !_calendarOpen),
          viewMode: _viewMode,
          onSelectViewMode: _setViewMode,
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
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: _calendarOpen
              ? PlannedMonthDropdown(
                  key: const ValueKey('planned-month-dropdown'),
                  selectedDate: _selectedDate,
                  tasks: tasks,
                  lists: lists,
                  accent: accent,
                  onSelect: _pickFromCalendar,
                )
              : PlannedWeekStrip(
                  key: const ValueKey('planned-week-strip'),
                  selectedDate: _selectedDate,
                  tasks: tasks,
                  lists: lists,
                  accent: accent,
                  compact: compact,
                  onSelect: _selectDate,
                ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = constraints.maxHeight;
              final peekHeight = math.min(132.0, maxHeight * 0.34);
              final travel = math.max(1.0, maxHeight - peekHeight);
              final sheetTop = travel * t;

              return Stack(
                children: [
                  if (t > 0.005)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: math.max(0, peekHeight - 16),
                      child: Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, -10 * (1 - t)),
                          child: PlannedWeekOverview(
                            days: PlannedLayout.weekDays(
                              PlannedLayout.weekStart(
                                _selectedDate,
                                mondayFirst: true,
                              ),
                            )
                                .map((d) => _dayFor(d, tasks, lists, accent))
                                .toList(),
                            selectedDate: _selectedDate,
                            accent: accent,
                            compact: compact,
                            onSelectDay: _selectDate,
                            onOpenTask: _openTask,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: sheetTop,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _Sheet(
                      isCollapsed: _isWeekOverview,
                      onHandleTap: _toggleSheetPosition,
                      onHandleVerticalDragUpdate: (details) =>
                          _onSheetDragUpdate(details, travel),
                      onHandleVerticalDragEnd: _onSheetDragEnd,
                      child: _dayPager(tasks, lists, accent, wide),
                    ),
                  ),
                ],
              );
            },
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
          ref.read(selectedPlannedDateProvider.notifier).select(date);
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
}

