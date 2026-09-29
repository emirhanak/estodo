import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../../l10n/app_localizations.dart';
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
/// timeline. Returns true when something was saved.
Future<bool?> showPlannedComposer(
  BuildContext context, {
  TodoTask? task,
  DateTime? date,
  DateTime? startAt,
  PlannedDraftKind kind = PlannedDraftKind.task,
}) {
  final accent = Theme.of(context).colorScheme.primary;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => PlannedComposer(
      task: task,
      date: date ?? DateTime.now(),
      startAt: startAt,
      kind: kind,
      accent: accent,
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
    this.kind = PlannedDraftKind.task,
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
            ? _draft.recurrence ?? PlannedNlp.dailyRule
            : _draft.recurrence,
      ),
    );
  }

  Future<void> _save() async {
    if (!_draft.canSave || _saving) return;
    setState(() => _saving = true);
    final controller = ref.read(taskControllerProvider);
    final existing = widget.task;
    try {
      if (existing != null) {
        await controller.updateTask(_draft.applyTo(existing));
      } else {
        await controller.createTask(
          title: _draft.title,
          notes: _draft.notes,
          listId: _draft.listId,
          iconKey: _draft.iconKey,
          colorValue: _draft.colorValue,
          isHabit: _draft.isHabit,
          dueAt: _draft.dueAt,
          startAt: _draft.startAt,
          durationMinutes: _draft.isAllDay ? null : _draft.durationMinutes,
          reminderAt: _draft.reminderAt,
          recurrence: _draft.recurrence,
          steps: _draft.steps,
          isImportant: _draft.isImportant,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorTryAgain)),
        );
      }
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
                  onClose: () => Navigator.of(context).pop(false),
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
                          ),
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
                            Navigator.of(context).pop(false);
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
                          enabled: _draft.canSave,
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

/// First step: what is it? Shows what the parser understood plus similar
/// entries the user already has.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = Color(draft.colorValue);
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      children: [
        if (draft.isHabit)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _Banner(
              icon: Icons.autorenew_rounded,
              color: color,
              text: l10n.composerHabitBanner,
            ),
          ),
        if (!parsed.isEmpty || similar.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              l10n.composerSuggestions,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                if (!parsed.isEmpty)
                  _SuggestionRow(
                    iconKey: draft.iconKey ??
                        TaskIconCatalog.suggestKeys(parsed.title, max: 1)
                            .firstOrNull,
                    color: color,
                    title: parsed.title,
                    subtitle: _parsedSummary(context, parsed, draft),
                    onTap: () => onApply(draft.applyNlp(parsed)),
                  ),
                for (final task in similar)
                  _SuggestionRow(
                    iconKey: task.iconKey ??
                        TaskIconCatalog.suggestKeys(task.title, max: 1)
                            .firstOrNull,
                    color: task.colorValue == null
                        ? color
                        : Color(task.colorValue!),
                    title: task.title,
                    subtitle: _taskSummary(context, task),
                    onTap: () => onApply(
                      draft.copyWith(
                        title: task.title,
                        iconKey: task.iconKey ?? draft.iconKey,
                        colorValue: task.colorValue ?? draft.colorValue,
                        durationMinutes:
                            task.durationMinutes ?? draft.durationMinutes,
                        startMinuteOfDay: task.startAt == null
                            ? draft.startMinuteOfDay
                            : task.startAt!.hour * 60 + task.startAt!.minute,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ] else
          _Banner(
            icon: Icons.auto_awesome_rounded,
            color: color,
            text: l10n.composerNlpHint,
          ),
      ],
    );
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                TaskIconCatalog.resolve(iconKey),
                size: 19,
                color: color,
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
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
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

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
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
