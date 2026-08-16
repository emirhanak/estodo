import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/date_time_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/entities/task_list.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_step.dart';
import '../../domain/entities/todo_task.dart';
import '../providers/task_providers.dart';
import 'animated_check_circle.dart';

Future<void> showTaskEditorSheet(
  BuildContext context, {
  TodoTask? task,
  String? initialTitle,
  String? initialListId,
  bool initialMyDay = false,
  bool initialImportant = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: true,
    builder: (_) => TaskEditorSheet(
      task: task,
      initialTitle: initialTitle,
      initialListId: initialListId,
      initialMyDay: initialMyDay,
      initialImportant: initialImportant,
    ),
  );
}

class TaskEditorSheet extends ConsumerStatefulWidget {
  const TaskEditorSheet({
    super.key,
    this.task,
    this.initialTitle,
    this.initialListId,
    this.initialMyDay = false,
    this.initialImportant = false,
  });

  final TodoTask? task;
  final String? initialTitle;
  final String? initialListId;
  final bool initialMyDay;
  final bool initialImportant;

  @override
  ConsumerState<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<TaskEditorSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _stepController = TextEditingController();
  final _stepFocus = FocusNode();

  String? _listId;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueAt;
  DateTime? _reminderAt;
  RecurrenceRule? _recurrence;
  late List<TaskStep> _steps;
  var _isImportant = false;
  var _isMyDay = false;
  var _isCompleted = false;
  var _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController.text = task?.title ?? widget.initialTitle ?? '';
    _notesController.text = task?.notes ?? '';
    _listId = task?.listId ?? widget.initialListId;
    _priority = task?.priority ?? TaskPriority.medium;
    _dueAt = task?.dueAt;
    _reminderAt = task?.reminderAt;
    _recurrence = task?.recurrence;
    _steps = List<TaskStep>.from(task?.steps ?? const <TaskStep>[]);
    _isImportant = task?.isImportant ?? widget.initialImportant;
    _isMyDay =
        task?.isInMyDay(DateTimeFormatter.todayKey()) ?? widget.initialMyDay;
    _isCompleted = task?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _stepController.dispose();
    _stepFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);
    final controller = ref.read(taskControllerProvider);

    try {
      if (_isEditing) {
        final existing = widget.task!;
        final hadCompleted = existing.isCompleted;
        await controller.updateTask(
          existing.copyWith(
            title: title,
            notes: _clean(_notesController.text),
            listId: _listId,
            priority: _priority,
            dueAt: _dueAt,
            reminderAt: _reminderAt,
            recurrence: _recurrence,
            steps: _steps,
            isImportant: _isImportant,
            isMyDay: _isMyDay,
            myDayDate: _isMyDay ? DateTimeFormatter.todayKey() : null,
            isCompleted: _isCompleted,
            completedAt:
                _isCompleted ? (existing.completedAt ?? DateTime.now()) : null,
          ),
        );
        if (!hadCompleted &&
            _isCompleted &&
            _recurrence != null &&
            _dueAt != null) {
          final nextDue = _recurrence!.nextOccurrence(_dueAt!);
          DateTime? nextReminder;
          if (_reminderAt != null) {
            final delta = _reminderAt!.difference(_dueAt!);
            nextReminder = nextDue.add(delta);
          }
          await controller.createTask(
            title: title,
            notes: _clean(_notesController.text),
            listId: _listId,
            priority: _priority,
            dueAt: nextDue,
            reminderAt: nextReminder,
            recurrence: _recurrence,
            steps: _steps
                .map((step) => step.copyWith(isCompleted: false))
                .toList(),
            isImportant: _isImportant,
            isMyDay: false,
          );
        }
      } else {
        await controller.createTask(
          title: title,
          notes: _notesController.text,
          listId: _listId,
          priority: _priority,
          dueAt: _dueAt,
          reminderAt: _reminderAt,
          recurrence: _recurrence,
          steps: _steps,
          isImportant: _isImportant,
          isMyDay: _isMyDay,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context);
    final picked = await showDatePicker(
      context: context,
      locale: locale.languageCode == 'tr'
          ? const Locale('tr', 'TR')
          : const Locale('en', 'US'),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDate: _dueAt ?? now,
    );
    if (picked != null) {
      setState(() => _dueAt = picked);
    }
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context);
    final date = await showDatePicker(
      context: context,
      locale: locale.languageCode == 'tr'
          ? const Locale('tr', 'TR')
          : const Locale('en', 'US'),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      initialDate: _reminderAt ?? _dueAt ?? now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? now),
    );
    if (time == null) return;

    setState(() {
      _reminderAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickRecurrence() async {
    final selected = await showModalBottomSheet<_RecurrenceResult>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (context) => _RecurrencePicker(initial: _recurrence),
    );
    if (!mounted || selected == null) return;
    setState(() => _recurrence = selected.cleared ? null : selected.rule);
  }

  String? _clean(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _addStepFromInput() {
    final text = _stepController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _steps = [
        ..._steps,
        TaskStep(id: const Uuid().v4(), title: text),
      ];
    });
    _stepController.clear();
    _stepFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(listsProvider).value ?? const <TaskList>[];
    final scheme = Theme.of(context).colorScheme;
    final accent = _listId == null
        ? scheme.primary
        : Color(
            lists.where((l) => l.id == _listId).map((l) => l.color).firstWhere(
                (_) => true,
                orElse: () => scheme.primary.toARGB32()),
          );
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _TitleRow(
                accent: accent,
                completed: _isCompleted,
                titleController: _titleController,
                onComplete: () => setState(() {
                  _isCompleted = !_isCompleted;
                }),
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 4),
              _StepsSection(
                steps: _steps,
                accent: accent,
                onToggle: (step) {
                  setState(() {
                    _steps = _steps
                        .map((s) => s.id == step.id
                            ? s.copyWith(isCompleted: !s.isCompleted)
                            : s)
                        .toList();
                  });
                },
                onRemove: (step) {
                  setState(() =>
                      _steps = _steps.where((s) => s.id != step.id).toList());
                },
                onRename: (step, newTitle) {
                  setState(() {
                    _steps = _steps
                        .map((s) =>
                            s.id == step.id ? s.copyWith(title: newTitle) : s)
                        .toList();
                  });
                },
                stepController: _stepController,
                stepFocus: _stepFocus,
                onAddStep: _addStepFromInput,
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.wb_sunny_outlined,
                title: _isMyDay ? l10n.addedToMyDay : l10n.addToMyDay,
                accent: accent,
                active: _isMyDay,
                onTap: () => setState(() => _isMyDay = !_isMyDay),
                onClear:
                    _isMyDay ? () => setState(() => _isMyDay = false) : null,
              ),
              _ActionTile(
                icon: Icons.notifications_active_outlined,
                title: _reminderAt == null ? l10n.remindMe : l10n.reminder,
                subtitle: _reminderAt == null
                    ? null
                    : DateTimeFormatter.reminderLabel(_reminderAt!,
                        locale: Localizations.localeOf(context).languageCode),
                accent: accent,
                active: _reminderAt != null,
                onTap: _pickReminder,
                onClear: _reminderAt == null
                    ? null
                    : () => setState(() => _reminderAt = null),
              ),
              _ActionTile(
                icon: Icons.event_outlined,
                title: _dueAt == null ? l10n.addDueDate : l10n.dueLabel,
                subtitle: _dueAt == null
                    ? null
                    : DateTimeFormatter.dueLabel(_dueAt!,
                        locale: Localizations.localeOf(context).languageCode),
                accent: accent,
                active: _dueAt != null,
                onTap: _pickDueDate,
                onClear:
                    _dueAt == null ? null : () => setState(() => _dueAt = null),
              ),
              _ActionTile(
                icon: Icons.repeat_rounded,
                title: _recurrence == null ? l10n.repeat : l10n.repeats,
                subtitle: _recurrence == null
                    ? null
                    : _localizedRecurrenceLabel(_recurrence!, l10n),
                accent: accent,
                active: _recurrence != null,
                onTap: _pickRecurrence,
                onClear: _recurrence == null
                    ? null
                    : () => setState(() => _recurrence = null),
              ),
              _ActionTile(
                icon: Icons.list_alt_rounded,
                title: l10n.list,
                subtitle: _listId == null
                    ? l10n.tasks
                    : lists
                        .firstWhere(
                          (l) => l.id == _listId,
                          orElse: () => TaskList(
                            id: '',
                            userId: '',
                            name: 'Tasks',
                            color: 0xFF8E8CD8,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        )
                        .name,
                accent: accent,
                active: _listId != null,
                onTap: () async {
                  final picked = await _showListPicker(
                    context,
                    lists,
                    onCreateList: () => _createListFromEditor(context),
                  );
                  if (picked != null) {
                    setState(() => _listId = picked == '' ? null : picked);
                  }
                },
              ),
              const SizedBox(height: 4),
              _PriorityRow(
                value: _priority,
                accent: accent,
                onChanged: (p) => setState(() => _priority = p),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.starred),
                secondary: Icon(
                  _isImportant ? Icons.star_rounded : Icons.star_border_rounded,
                  color: _isImportant ? accent : null,
                ),
                value: _isImportant,
                activeThumbColor: accent,
                onChanged: (value) => setState(() => _isImportant = value),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: l10n.addNote,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    icon: Icon(
                      Icons.notes_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isEditing)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l10n.deleteTask),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.deleteTaskConfirmTitle),
                        content: Text(
                          l10n.deleteTaskConfirmBody(widget.task!.title),
                        ),
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
                    await ref
                        .read(taskControllerProvider)
                        .deleteTask(widget.task!);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_isEditing ? l10n.save : l10n.createTask),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<String?> _createListFromEditor(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.newList),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.listName),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
  if (name == null || name.isEmpty || !context.mounted) return null;
  final list = await ProviderScope.containerOf(context, listen: false)
      .read(taskControllerProvider)
      .createList(name, 0xFF5B5FC7);
  return list.id;
}

Future<String?> _showListPicker(
  BuildContext context,
  List<TaskList> lists, {
  required Future<String?> Function() onCreateList,
}) async {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inbox_rounded),
              title: Text(l10n.tasks),
              onTap: () => Navigator.of(context).pop(''),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: Text(l10n.newList),
              onTap: () async {
                Navigator.of(context).pop(await onCreateList());
              },
            ),
            const Divider(height: 1),
            for (final list in lists)
              ListTile(
                leading: CircleAvatar(
                  radius: 8,
                  backgroundColor: Color(list.color),
                ),
                title: Text(list.name),
                onTap: () => Navigator.of(context).pop(list.id),
              ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.accent,
    required this.completed,
    required this.titleController,
    required this.onComplete,
    required this.onClose,
  });

  final Color accent;
  final bool completed;
  final TextEditingController titleController;
  final VoidCallback onComplete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: AnimatedCheckCircle(
            value: completed,
            color: accent,
            onChanged: (_) => onComplete(),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              controller: titleController,
              maxLines: 4,
              minLines: 1,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                decoration: completed
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).taskName,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).close,
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _StepsSection extends StatelessWidget {
  const _StepsSection({
    required this.steps,
    required this.accent,
    required this.onToggle,
    required this.onRemove,
    required this.onRename,
    required this.stepController,
    required this.stepFocus,
    required this.onAddStep,
  });

  final List<TaskStep> steps;
  final Color accent;
  final ValueChanged<TaskStep> onToggle;
  final ValueChanged<TaskStep> onRemove;
  final void Function(TaskStep step, String newTitle) onRename;
  final TextEditingController stepController;
  final FocusNode stepFocus;
  final VoidCallback onAddStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                children: [
                  AnimatedCheckCircle(
                    value: step.isCompleted,
                    color: accent,
                    size: 20,
                    onChanged: (_) => onToggle(step),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: step.title,
                      onChanged: (value) => onRename(step, value),
                      style: TextStyle(
                        fontSize: 14,
                        decoration: step.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: step.isCompleted
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.delete,
                    iconSize: 18,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => onRemove(step),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.add_rounded,
                      size: 20, color: scheme.onSurfaceVariant),
                ),
                Expanded(
                  child: TextField(
                    controller: stepController,
                    focusNode: stepFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onAddStep(),
                    decoration: InputDecoration(
                      hintText: l10n.addStep,
                      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.accent,
    required this.active,
    required this.onTap,
    this.subtitle,
    this.onClear,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: Icon(icon, color: active ? accent : scheme.onSurfaceVariant),
        title: Text(
          title,
          style: TextStyle(
            color: active ? accent : scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: onClear == null
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
        onTap: onTap,
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final TaskPriority value;
  final Color accent;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: SegmentedButton<TaskPriority>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: accent.withValues(alpha: 0.18),
                selectedForegroundColor: accent,
              ),
              segments: [
                for (final p in TaskPriority.values)
                  ButtonSegment(
                      value: p, label: Text(_priorityLabel(p, context))),
              ],
              selected: {value},
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

String _priorityLabel(TaskPriority priority, BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return switch (priority) {
    TaskPriority.low => l10n.low,
    TaskPriority.medium => l10n.medium,
    TaskPriority.high => l10n.high,
  };
}

class _RecurrenceResult {
  const _RecurrenceResult({this.rule, this.cleared = false});
  final RecurrenceRule? rule;
  final bool cleared;
}

String _localizedFrequency(RecurrenceFrequency freq, AppLocalizations l10n) {
  return switch (freq) {
    RecurrenceFrequency.daily => l10n.freqDaily,
    RecurrenceFrequency.weekdays => l10n.freqWeekdays,
    RecurrenceFrequency.weekly => l10n.freqWeekly,
    RecurrenceFrequency.monthly => l10n.freqMonthly,
    RecurrenceFrequency.yearly => l10n.freqYearly,
  };
}

String _localizedRecurrenceLabel(RecurrenceRule rule, AppLocalizations l10n) {
  return _localizedFrequency(rule.frequency, l10n);
}

class _RecurrencePicker extends StatelessWidget {
  const _RecurrencePicker({this.initial});

  final RecurrenceRule? initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  l10n.repeat,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                if (initial != null)
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pop(const _RecurrenceResult(cleared: true)),
                    child: Text(l10n.clear),
                  ),
              ],
            ),
          ),
          for (final freq in RecurrenceFrequency.values)
            ListTile(
              leading: const Icon(Icons.repeat_rounded),
              title: Text(_localizedFrequency(freq, l10n)),
              trailing: initial?.frequency == freq
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.of(context).pop(
                _RecurrenceResult(rule: RecurrenceRule(frequency: freq)),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
