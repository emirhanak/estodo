import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/recurrence_rule.dart';
import '../../../../domain/entities/task_step.dart';
import '../../../utils/planned_draft.dart';
import '../../../utils/planned_layout.dart';
import '../planned_capsule.dart';
import '../planned_format.dart';
import 'composer_time_wheel.dart';

/// Second composer step: when does it happen, how long, how often.
class ComposerScheduleStep extends StatefulWidget {
  const ComposerScheduleStep({
    super.key,
    required this.draft,
    required this.onDraftChanged,
    required this.onPickDate,
    required this.onPickRepeat,
    required this.onPickDuration,
  });

  final PlannedDraft draft;
  final ValueChanged<PlannedDraft> onDraftChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickRepeat;
  final VoidCallback onPickDuration;

  @override
  State<ComposerScheduleStep> createState() => _ComposerScheduleStepState();
}

class _ComposerScheduleStepState extends State<ComposerScheduleStep> {
  final _stepController = TextEditingController();
  late final TextEditingController _notesController =
      TextEditingController(text: widget.draft.notes ?? '');

  @override
  void dispose() {
    _stepController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  PlannedDraft get _draft => widget.draft;

  void _update(PlannedDraft draft) => widget.onDraftChanged(draft);

  void _addStep() {
    final title = _stepController.text.trim();
    if (title.isEmpty) return;
    _update(
      _draft.copyWith(
        steps: [
          ..._draft.steps,
          TaskStep(
            id: 'step-${DateTime.now().microsecondsSinceEpoch}',
            title: title,
          ),
        ],
      ),
    );
    _stepController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Color(_draft.colorValue);
    final locale = PlannedFormat.intlLocale(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _Card(
          children: [
            _Row(
              icon: Icons.calendar_today_rounded,
              color: color,
              label: DateFormat('EEE, d MMMM y', locale).format(_draft.date),
              trailing: _relativeLabel(l10n, _draft.date),
              onTap: widget.onPickDate,
            ),
            if (_draft.recurrence != null)
              _Row(
                icon: Icons.autorenew_rounded,
                color: color,
                label: _repeatLabel(l10n, _draft.recurrence!),
                trailing: _weekdayLabel(context, _draft.recurrence!),
                onTap: widget.onPickRepeat,
              ),
            _Row(
              icon: Icons.notifications_none_rounded,
              color: color,
              label: l10n.composerReminder,
              trailing: _reminderLabel(l10n, _draft.reminderMinutesBefore),
              onTap: _pickReminder,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionLabel(
          label: l10n.composerTime,
          trailing: IconButton(
            tooltip: _draft.isAllDay ? l10n.composerAddTime : l10n.allDay,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _draft.isAllDay
                  ? Icons.more_time_rounded
                  : Icons.wb_sunny_outlined,
              size: 20,
            ),
            onPressed: _toggleAllDay,
          ),
        ),
        _Card(
          padding: EdgeInsets.zero,
          children: [
            if (_draft.isAllDay)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny_rounded, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.allDay,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleAllDay,
                      style: TextButton.styleFrom(foregroundColor: color),
                      child: Text(l10n.composerAddTime),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ComposerTimeWheel(
                  startMinuteOfDay: _draft.startMinuteOfDay ?? 9 * 60,
                  durationMinutes: _draft.durationMinutes,
                  color: color,
                  onChanged: (minute) =>
                      _update(_draft.copyWith(startMinuteOfDay: minute)),
                ),
              ),
          ],
        ),
        if (!_draft.isAllDay) ...[
          const SizedBox(height: 14),
          _SectionLabel(
            label: l10n.composerDuration,
            trailing: IconButton(
              tooltip: l10n.customDuration,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.more_horiz_rounded, size: 20),
              onPressed: widget.onPickDuration,
            ),
          ),
          _DurationChips(
            minutes: _draft.durationMinutes,
            color: color,
            onChanged: (minutes) =>
                _update(_draft.copyWith(durationMinutes: minutes)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            _ActionChip(
              icon: Icons.autorenew_rounded,
              label: l10n.composerRepeat,
              active: _draft.recurrence != null,
              color: color,
              onTap: widget.onPickRepeat,
            ),
            const SizedBox(width: 10),
            _ActionChip(
              icon: Icons.star_rounded,
              label: l10n.important,
              active: _draft.isImportant,
              color: color,
              onTap: () =>
                  _update(_draft.copyWith(isImportant: !_draft.isImportant)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Card(
          children: [
            for (final step in _draft.steps)
              _StepRow(
                step: step,
                color: color,
                onToggle: () => _update(
                  _draft.copyWith(
                    steps: [
                      for (final item in _draft.steps)
                        if (item.id == step.id)
                          item.copyWith(isCompleted: !item.isCompleted)
                        else
                          item,
                    ],
                  ),
                ),
                onRemove: () => _update(
                  _draft.copyWith(
                    steps: _draft.steps
                        .where((item) => item.id != step.id)
                        .toList(),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 8, 2),
              child: Row(
                children: [
                  Icon(
                    Icons.add_task_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _stepController,
                      onSubmitted: (_) => _addStep(),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        filled: false,
                        isDense: true,
                        border: InputBorder.none,
                        hintText: l10n.composerSubtaskHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 5,
                onChanged: (value) => _update(
                  _draft.copyWith(notes: value.trim().isEmpty ? null : value),
                ),
                decoration: InputDecoration(
                  filled: false,
                  isDense: true,
                  border: InputBorder.none,
                  hintText: l10n.composerNotesHint,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleAllDay() {
    if (_draft.isAllDay) {
      final fallback = PlannedLayout.roundToQuarter(DateTime.now());
      _update(
        _draft.copyWith(
          startMinuteOfDay: fallback.hour * 60 + fallback.minute,
        ),
      );
    } else {
      _update(_draft.copyWith(startMinuteOfDay: null));
    }
  }

  Future<void> _pickReminder() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<PlannedDraft>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: Text(l10n.composerReminderNone),
              onTap: () => Navigator.of(sheetContext).pop(
                _draft.copyWith(reminderMinutesBefore: null),
              ),
            ),
            for (final lead in PlannedDraft.reminderPresets)
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(_reminderLabel(l10n, lead)),
                onTap: () => Navigator.of(sheetContext).pop(
                  _draft.copyWith(reminderMinutesBefore: lead),
                ),
              ),
          ],
        ),
      ),
    );
    if (selected != null) _update(selected);
  }
}

String _reminderLabel(AppLocalizations l10n, int? lead) {
  if (lead == null) return l10n.composerReminderNone;
  if (lead == 0) return l10n.composerReminderOnTime;
  if (lead >= 60) return l10n.plannedHoursShort(lead ~/ 60);
  return l10n.composerReminderBefore(lead);
}

String _repeatLabel(AppLocalizations l10n, RecurrenceRule rule) {
  return switch (rule.frequency) {
    RecurrenceFrequency.daily => l10n.composerEveryDays(rule.interval),
    RecurrenceFrequency.monthly => l10n.composerEveryMonths(rule.interval),
    RecurrenceFrequency.weekdays => l10n.composerRepeatWeekdays,
    RecurrenceFrequency.yearly => l10n.composerRepeatYearly,
    RecurrenceFrequency.weekly => l10n.composerEveryWeeks(rule.interval),
  };
}

String? _weekdayLabel(BuildContext context, RecurrenceRule rule) {
  if (rule.weekdays.isEmpty) return null;
  final narrow = MaterialLocalizations.of(context).narrowWeekdays;
  final days = rule.weekdays.map((day) => narrow[day % 7]).join(' ');
  return days;
}

String _relativeLabel(AppLocalizations l10n, DateTime date) {
  final today = PlannedLayout.dayOf(DateTime.now());
  final diff = PlannedLayout.dayOf(date).difference(today).inDays;
  if (diff == 0) return l10n.plannedToday;
  if (diff == 1) return l10n.tomorrow;
  if (diff == -1) return l10n.yesterday;
  if (diff > 1) return l10n.composerInDays(diff);
  return l10n.composerDaysAgo(-diff);
}

class _Card extends StatelessWidget {
  const _Card({required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 2, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: scheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChips extends StatelessWidget {
  const _DurationChips({
    required this.minutes,
    required this.color,
    required this.onChanged,
  });

  final int minutes;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final presets = <int>{...PlannedDraft.durationPresets, minutes}.toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final preset in presets)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(preset);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: preset == minutes ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    PlannedFormat.duration(l10n, preset),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: preset == minutes
                              ? PlannedCapsule.foregroundOn(color)
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.16)
              : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(color: color, width: 1.4)
              : Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: active ? color : scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: active ? color : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.color,
    required this.onToggle,
    required this.onRemove,
  });

  final TaskStep step;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.lightImpact();
              onToggle();
            },
            child: Icon(
              step.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              size: 20,
              color: step.isCompleted ? color : scheme.outline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration:
                        step.isCompleted ? TextDecoration.lineThrough : null,
                    color: step.isCompleted
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, size: 18, color: scheme.outline),
          ),
        ],
      ),
    );
  }
}
