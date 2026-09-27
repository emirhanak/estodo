import '../../domain/entities/recurrence_rule.dart';
import '../../domain/entities/task_step.dart';
import '../../domain/entities/todo_task.dart';
import 'planned_layout.dart';
import 'planned_nlp.dart';

/// The planned tab creates two kinds of entries: one-off plans and habits that
/// repeat by design.
enum PlannedDraftKind { task, habit }

/// Immutable state of the planned composer. Kept widget free so the flow can
/// be unit tested end to end.
class PlannedDraft {
  const PlannedDraft({
    required this.title,
    required this.date,
    required this.colorValue,
    this.iconKey,
    this.startMinuteOfDay,
    this.durationMinutes = defaultDuration,
    this.recurrence,
    this.steps = const <TaskStep>[],
    this.notes,
    this.reminderMinutesBefore,
    this.kind = PlannedDraftKind.task,
    this.listId,
    this.isImportant = false,
  });

  static const defaultDuration = 30;
  static const durationPresets = <int>[15, 30, 45, 60, 120];
  static const reminderPresets = <int>[0, 5, 15, 60];

  final String title;
  final DateTime date;
  final int colorValue;
  final String? iconKey;

  /// Minutes past midnight, or null for an all-day entry.
  final int? startMinuteOfDay;
  final int durationMinutes;
  final RecurrenceRule? recurrence;
  final List<TaskStep> steps;
  final String? notes;

  /// Lead time of the reminder, or null when there is no reminder.
  final int? reminderMinutesBefore;
  final PlannedDraftKind kind;
  final String? listId;
  final bool isImportant;

  bool get isHabit => kind == PlannedDraftKind.habit;

  bool get isAllDay => startMinuteOfDay == null;

  bool get canSave => title.trim().isNotEmpty;

  DateTime get day => PlannedLayout.dayOf(date);

  DateTime? get startAt {
    final minute = startMinuteOfDay;
    if (minute == null) return null;
    return day.add(Duration(minutes: minute));
  }

  DateTime? get endAt => startAt?.add(Duration(minutes: durationMinutes));

  DateTime? get reminderAt {
    final lead = reminderMinutesBefore;
    if (lead == null) return null;
    final start = startAt;
    if (start != null) return start.subtract(Duration(minutes: lead));
    // All-day entries nudge in the morning of the day itself.
    return day.add(const Duration(hours: 9));
  }

  /// The `dueAt` value the task repository expects: the day, carrying the
  /// start time when there is one.
  DateTime get dueAt => startAt ?? day;

  PlannedDraft copyWith({
    String? title,
    DateTime? date,
    int? colorValue,
    Object? iconKey = _unset,
    Object? startMinuteOfDay = _unset,
    int? durationMinutes,
    Object? recurrence = _unset,
    List<TaskStep>? steps,
    Object? notes = _unset,
    Object? reminderMinutesBefore = _unset,
    PlannedDraftKind? kind,
    Object? listId = _unset,
    bool? isImportant,
  }) {
    return PlannedDraft(
      title: title ?? this.title,
      date: date ?? this.date,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey == _unset ? this.iconKey : iconKey as String?,
      startMinuteOfDay: startMinuteOfDay == _unset
          ? this.startMinuteOfDay
          : startMinuteOfDay as int?,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      recurrence: recurrence == _unset
          ? this.recurrence
          : recurrence as RecurrenceRule?,
      steps: steps ?? this.steps,
      notes: notes == _unset ? this.notes : notes as String?,
      reminderMinutesBefore: reminderMinutesBefore == _unset
          ? this.reminderMinutesBefore
          : reminderMinutesBefore as int?,
      kind: kind ?? this.kind,
      listId: listId == _unset ? this.listId : listId as String?,
      isImportant: isImportant ?? this.isImportant,
    );
  }

  /// A blank draft for [date], starting at the next free quarter hour.
  factory PlannedDraft.forDate(
    DateTime date, {
    required int colorValue,
    DateTime? startAt,
    DateTime? now,
    PlannedDraftKind kind = PlannedDraftKind.task,
  }) {
    final clock = now ?? DateTime.now();
    final start = startAt ??
        (PlannedLayout.isSameDay(date, clock)
            ? PlannedLayout.roundToQuarter(clock)
            : PlannedLayout.dayOf(date).add(const Duration(hours: 9)));
    return PlannedDraft(
      title: '',
      date: PlannedLayout.dayOf(date),
      colorValue: colorValue,
      startMinuteOfDay: start.hour * 60 + start.minute,
      kind: kind,
      recurrence: kind == PlannedDraftKind.habit
          ? const RecurrenceRule(frequency: RecurrenceFrequency.daily)
          : null,
    );
  }

  /// Loads an existing task into the composer for editing.
  factory PlannedDraft.fromTask(TodoTask task, {required int fallbackColor}) {
    final start = task.startAt;
    return PlannedDraft(
      title: task.title,
      date: PlannedLayout.dayOf(task.dueAt ?? task.createdAt),
      colorValue: task.colorValue ?? fallbackColor,
      iconKey: task.iconKey,
      startMinuteOfDay: start == null ? null : start.hour * 60 + start.minute,
      durationMinutes: task.durationMinutes ?? defaultDuration,
      recurrence: task.recurrence,
      steps: task.steps,
      notes: task.notes,
      reminderMinutesBefore: _leadOf(task),
      kind: task.isHabit ? PlannedDraftKind.habit : PlannedDraftKind.task,
      listId: task.listId,
      isImportant: task.isImportant,
    );
  }

  static int? _leadOf(TodoTask task) {
    final reminder = task.reminderAt;
    final start = task.startAt;
    if (reminder == null) return null;
    if (start == null) return 0;
    final lead = start.difference(reminder).inMinutes;
    return lead < 0 ? 0 : lead;
  }

  /// Folds what the title parser understood into the draft.
  PlannedDraft applyNlp(PlannedNlpResult result) {
    if (result.isEmpty) return copyWith(title: result.title);
    return copyWith(
      title: result.title,
      date: result.date ?? date,
      startMinuteOfDay:
          result.allDay ? null : result.startMinuteOfDay ?? startMinuteOfDay,
      durationMinutes: result.durationMinutes ?? durationMinutes,
      recurrence: result.recurrence ?? recurrence,
      kind: result.recurrence != null && kind == PlannedDraftKind.task
          ? PlannedDraftKind.task
          : kind,
    );
  }

  /// Applies the draft onto [task] so an edit keeps ids and completion state.
  TodoTask applyTo(TodoTask task) {
    return task.copyWith(
      title: title.trim(),
      notes: notes,
      iconKey: iconKey,
      colorValue: colorValue,
      isHabit: isHabit,
      dueAt: dueAt,
      startAt: startAt,
      durationMinutes: isAllDay ? null : durationMinutes,
      reminderAt: reminderAt,
      recurrence: recurrence,
      steps: steps,
      listId: listId,
      isImportant: isImportant,
    );
  }
}

const _unset = Object();
