import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/task_list.dart';
import '../../../../domain/entities/todo_task.dart';
import '../../../providers/task_providers.dart';
import '../../../utils/planned_draft.dart';
import '../../../utils/planned_layout.dart';
import '../../../utils/planned_nlp.dart';
import '../../../utils/task_icon_catalog.dart';
import '../planned_capsule.dart';
import '../planned_format.dart';
import 'composer_header.dart';
import 'composer_pickers.dart';
import 'composer_schedule_step.dart';
import '../../focus_mode_sheet.dart';

/// Opens the planned tab's own creation flow: name it, then place it on the
/// timeline. Animates smoothly from bottom-right to top-left.
/// Completes with the saved entry's day, or null when dismissed without saving.
Future<DateTime?> showPlannedComposer(
  BuildContext context, {
  TodoTask? task,
  DateTime? date,
  DateTime? startAt,
  PlannedDraftKind kind = PlannedDraftKind.habit,
}) {
  final accent = Theme.of(context).colorScheme.primary;
  return Navigator.of(context).push<DateTime>(
    PageRouteBuilder<DateTime>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (routeContext, _, __) => SafeArea(
        top: false,
        bottom: false,
        child: PlannedComposer(
          task: task,
          date: date ?? DateTime.now(),
          startAt: startAt,
          kind: kind,
          accent: accent,
        ),
      ),
      transitionsBuilder: (routeContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.32, 0.36),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              alignment: Alignment.bottomRight,
              scale: Tween<double>(
                begin: 0.24,
                end: 1.0,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

class PlannedComposer extends ConsumerStatefulWidget {
  const PlannedComposer({
    super.key,
    required this.date,
    required this.accent,
    this.task,
    this.startAt,
    this.kind = PlannedDraftKind.habit,
  });

  final TodoTask? task;
  final DateTime date;
  final DateTime? startAt;
  final PlannedDraftKind kind;
  final Color accent;

  @override
  ConsumerState<PlannedComposer> createState() => _PlannedComposerState();
}

class _PlannedComposerState extends ConsumerState<PlannedComposer> {
  late PlannedDraft _draft = widget.task == null
      ? PlannedDraft.forDate(
          widget.date,
          colorValue: widget.accent.toARGB32(),
          startAt: widget.startAt,
          kind: widget.kind,
        )
      : PlannedDraft.fromTask(
          widget.task!,
          fallbackColor: widget.accent.toARGB32(),
        );

  late final TextEditingController _titleController =
      TextEditingController(text: _draft.title);
  final _titleFocus = FocusNode();

  late int _step = widget.task == null ? 0 : 1;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (!_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _setDraft(PlannedDraft draft) => setState(() => _draft = draft);

  void _onTitleChanged(String value) {
    setState(() => _draft = _draft.copyWith(title: value));
  }

  /// Reads the typed title through the parser and moves on to the schedule.
  void _continue() {
    if (!_draft.canSave) return;
    final parsed = PlannedNlp.parse(_titleController.text);
    final next = _draft.applyNlp(parsed);
    _titleController.text = next.title;
    _titleFocus.unfocus();
    setState(() {
      _draft = next;
      _step = 1;
    });
  }

  Future<void> _pickAppearance() async {
    final result = await showComposerAppearanceSheet(
      context,
      iconKey: _draft.iconKey,
      colorValue: _draft.colorValue,
      title: _draft.title,
    );
    if (result == null) return;
    _setDraft(
      _draft.copyWith(iconKey: result.iconKey, colorValue: result.colorValue),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.date,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) _setDraft(_draft.copyWith(date: picked));
  }

  Future<void> _pickRepeat() async {
    final result = await showComposerRepeatSheet(
      context,
      rule: _draft.recurrence,
      startDate: _draft.date,
      color: Color(_draft.colorValue),
    );
    if (result == null) return;
    _setDraft(
      _draft.copyWith(
        recurrence: result.value,
        // A habit without a rhythm is just a task, so keep the kinds honest.
        kind: result.value == null ? PlannedDraftKind.task : _draft.kind,
      ),
    );
  }

  Future<void> _pickDuration() async {
    final minutes = await showComposerDurationSheet(
      context,
      minutes: _draft.durationMinutes,
      color: Color(_draft.colorValue),
    );
    if (minutes != null && minutes > 0) {
      _setDraft(_draft.copyWith(durationMinutes: minutes));
    }
  }

  void _changeKind(PlannedDraftKind kind) {
    _setDraft(
      _draft.copyWith(
        kind: kind,
        recurrence: kind == PlannedDraftKind.habit
            ? (_draft.recurrence ?? PlannedNlp.dailyRule)
            : null,
      ),
    );
  }

  Future<void> _save() async {
    final currentTitle = _titleController.text.trim();
    final draftToSave = _draft.copyWith(
      title: currentTitle.isNotEmpty ? currentTitle : _draft.title,
    );
    if (!draftToSave.canSave || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final controller = ref.read(taskControllerProvider);
    final existing = widget.task;
    try {
      if (existing != null) {
        await controller.updateTask(draftToSave.applyTo(existing));
      } else {
        await controller.createTask(
          title: draftToSave.title,
          notes: draftToSave.notes,
          listId: draftToSave.listId,
          iconKey: draftToSave.iconKey,
          colorValue: draftToSave.colorValue,
          isHabit: draftToSave.isHabit,
          dueAt: draftToSave.dueAt,
          startAt: draftToSave.startAt,
          durationMinutes:
              draftToSave.isAllDay ? null : draftToSave.durationMinutes,
          reminderAt: draftToSave.reminderAt,
          recurrence: draftToSave.recurrence,
          steps: draftToSave.steps,
          isImportant: draftToSave.isImportant,
        );
      }
      if (mounted) Navigator.of(context).pop(draftToSave.dueAt);
    } catch (e) {
      debugPrint('Error saving planned task: $e');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? get _summary {
    if (_step == 0) return null;
    final l10n = AppLocalizations.of(context);
    final start = _draft.startAt;
    if (start == null) return l10n.allDay;
    final end = _draft.endAt!;
    return '${PlannedFormat.time(start)} – ${PlannedFormat.time(end)} '
        '(${PlannedFormat.duration(l10n, _draft.durationMinutes)})';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final color = Color(_draft.colorValue);

    final viewPaddingBottom = MediaQuery.viewPaddingOf(context).bottom;
    final bottomPadding =
        insets > 0 ? insets + 10 : math.max(viewPaddingBottom + 10, 16.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: size.height * 0.94,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: scheme.surfaceContainerHigh,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ComposerHeader(
                  draft: _draft,
                  controller: _titleController,
                  focusNode: _titleFocus,
                  summary: _summary,
                  onClose: () => Navigator.of(context).pop(null),
                  onAppearance: _pickAppearance,
                  onTitleChanged: _onTitleChanged,
                  onSubmitted: _step == 0 ? _continue : _save,
                  kindSwitch: _isEditing
                      ? null
                      : ComposerKindSwitch(
                          kind: _draft.kind,
                          foreground: PlannedCapsule.foregroundOn(color),
                          background: color,
                          onChanged: _changeKind,
                        ),
                ),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _step == 0
                        ? _IntentStep(
                            key: const ValueKey('composer-intent'),
                            draft: _draft,
                            tasks: ref.watch(tasksProvider).value ??
                                const <TodoTask>[],
                            onApply: (draft) {
                              _titleController.text = draft.title;
                              _titleFocus.unfocus();
                              setState(() {
                                _draft = draft;
                                _step = 1;
                              });
                            },
                          )
                        : ComposerScheduleStep(
                            key: const ValueKey('composer-schedule'),
                            draft: _draft,
                            onDraftChanged: _setDraft,
                            onPickDate: _pickDate,
                            onPickRepeat: _pickRepeat,
                            onPickDuration: _pickDuration,
                            lists: ref.watch(listsProvider).value ??
                                const <TaskList>[],
                          ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(
                      '${l10n.errorTryAgain}\n$_error',
                      style: TextStyle(color: scheme.error, fontSize: 12.5),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
                  child: Row(
                    children: [
                      if (_step == 1 && !_isEditing) ...[
                        _BackButton(
                          color: color,
                          onTap: () => setState(() => _step = 0),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (_isEditing && widget.task != null) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(Icons.timer_outlined,
                              color: color, size: 20),
                          label: Text(
                            l10n.focusMode,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(null);
                            showFocusModeSheet(context, task: widget.task!);
                          },
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: _PrimaryButton(
                          label: _step == 0
                              ? l10n.composerContinue
                              : _isEditing
                                  ? l10n.save
                                  : _draft.isHabit
                                      ? l10n.composerCreateHabit
                                      : l10n.composerCreateTask,
                          color: color,
                          busy: _saving,
                          enabled: _draft.canSave ||
                              _titleController.text.trim().isNotEmpty,
                          onTap: _step == 0 ? _continue : _save,
                        ),
                      ),
                    ],
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

/// First step: Structured-style quick suggestions (Screenshot 4) plus NLP
/// parsing and similar user tasks.
class _IntentStep extends StatelessWidget {
  const _IntentStep({
    super.key,
    required this.draft,
    required this.tasks,
    required this.onApply,
  });

  final PlannedDraft draft;
  final List<TodoTask> tasks;
  final ValueChanged<PlannedDraft> onApply;

  static List<
      ({
        String title,
        String iconKey,
        int colorValue,
        int startMinuteOfDay,
        int durationMinutes,
      })> _presets(bool isTr) {
    return [
      (
        title: isTr ? 'E-postalara Yanıt Ver' : 'Reply to Emails',
        iconKey: 'mail',
        colorValue: 0xFFE05A47,
        startMinuteOfDay: 10 * 60,
        durationMinutes: 15,
      ),
      (
        title: isTr ? 'Film İzle' : 'Watch a Movie',
        iconKey: 'tv',
        colorValue: 0xFF9B51E0,
        startMinuteOfDay: 20 * 60,
        durationMinutes: 90,
      ),
      (
        title: isTr ? 'Koşuya Çık!' : 'Go for a Run!',
        iconKey: 'run',
        colorValue: 0xFF27AE60,
        startMinuteOfDay: 12 * 60,
        durationMinutes: 60,
      ),
      (
        title: isTr ? 'Alışveriş Yap' : 'Go Grocery Shopping',
        iconKey: 'groceries',
        colorValue: 0xFF2D9CDB,
        startMinuteOfDay: 17 * 60,
        durationMinutes: 60,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = Color(draft.colorValue);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final query = draft.title.trim().toLowerCase();
    final parsed = PlannedNlp.parse(draft.title);

    final similar = query.length < 2
        ? const <TodoTask>[]
        : tasks
            .where((task) =>
                task.title.toLowerCase().contains(query) &&
                task.title.toLowerCase() != query)
            .take(3)
            .toList();

    final presets = _presets(isTr);

    final rows = <Widget>[
      if (!parsed.isEmpty)
        _SuggestionRow(
          iconKey: draft.iconKey ??
              TaskIconCatalog.suggestKeys(parsed.title, max: 1).firstOrNull,
          color: color,
          title: parsed.title,
          subtitle: _parsedSummary(context, parsed, draft),
          onTap: () => onApply(draft.applyNlp(parsed)),
        ),
      for (final task in similar)
        _SuggestionRow(
          iconKey: task.iconKey ??
              TaskIconCatalog.suggestKeys(task.title, max: 1).firstOrNull,
          color: task.colorValue == null ? color : Color(task.colorValue!),
          title: task.title,
          subtitle: _taskSummary(context, task),
          onTap: () => onApply(
            draft.copyWith(
              title: task.title,
              iconKey: task.iconKey ?? draft.iconKey,
              colorValue: task.colorValue ?? draft.colorValue,
              durationMinutes: task.durationMinutes ?? draft.durationMinutes,
              startMinuteOfDay: task.startAt == null
                  ? draft.startMinuteOfDay
                  : task.startAt!.hour * 60 + task.startAt!.minute,
            ),
          ),
        ),
      for (final preset in presets)
        _SuggestionRow(
          iconKey: preset.iconKey,
          color: Color(preset.colorValue),
          title: preset.title,
          subtitle: _rangeSummary(
            l10n,
            draft.date,
            preset.startMinuteOfDay,
            preset.durationMinutes,
          ),
          onTap: () => onApply(
            draft.copyWith(
              title: preset.title,
              iconKey: preset.iconKey,
              colorValue: preset.colorValue,
              startMinuteOfDay: preset.startMinuteOfDay,
              durationMinutes: preset.durationMinutes,
            ),
          ),
        ),
    ];

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: rows.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 68,
        endIndent: 16,
        color: scheme.outlineVariant.withValues(alpha: 0.35),
      ),
      itemBuilder: (context, index) => rows[index],
    );
  }

  String _rangeSummary(
    AppLocalizations l10n,
    DateTime date,
    int startMinuteOfDay,
    int durationMinutes,
  ) {
    final start =
        PlannedLayout.dayOf(date).add(Duration(minutes: startMinuteOfDay));
    final end = start.add(Duration(minutes: durationMinutes));
    return '${PlannedFormat.time(start)}–${PlannedFormat.time(end)} '
        '(${PlannedFormat.duration(l10n, durationMinutes)})';
  }

  String _parsedSummary(
    BuildContext context,
    PlannedNlpResult parsed,
    PlannedDraft draft,
  ) {
    final l10n = AppLocalizations.of(context);
    final locale = PlannedFormat.intlLocale(context);
    final parts = <String>[];
    final date = parsed.date ?? draft.date;
    parts.add(DateFormat('EEE, d MMM', locale).format(date));
    if (parsed.allDay) {
      parts.add(l10n.allDay);
    } else {
      final minute = parsed.startMinuteOfDay ?? draft.startMinuteOfDay;
      if (minute != null) {
        final start = PlannedLayout.dayOf(date).add(Duration(minutes: minute));
        parts.add(PlannedFormat.time(start));
      }
    }
    parts.add(
      PlannedFormat.duration(
        l10n,
        parsed.durationMinutes ?? draft.durationMinutes,
      ),
    );
    return parts.join(' · ');
  }

  String _taskSummary(BuildContext context, TodoTask task) {
    final l10n = AppLocalizations.of(context);
    final start = task.startAt;
    if (start == null) return l10n.allDay;
    return '${PlannedFormat.time(start)} · '
        '${PlannedFormat.duration(l10n, task.durationMinutes ?? PlannedDraft.defaultDuration)}';
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.iconKey,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String? iconKey;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconFg = PlannedCapsule.foregroundOn(color);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                TaskIconCatalog.resolve(iconKey),
                size: 20,
                color: iconFg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_outward_rounded, size: 18, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = PlannedCapsule.foregroundOn(color);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: enabled ? color : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: enabled && !busy ? onTap : null,
          child: SizedBox(
            height: 54,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: foreground,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: enabled ? foreground : scheme.onSurfaceVariant,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(Icons.arrow_back_rounded, color: color),
        ),
      ),
    );
  }
}
