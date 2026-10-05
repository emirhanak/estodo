import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'focus_mode_sheet.dart';

part 'task_editor_sections.dart';

Future<void> showTaskEditorSheet(
  BuildContext context, {
  TodoTask? task,
  String? initialTitle,
  String? initialListId,
  DateTime? initialDueDate,
  DateTime? initialStartAt,
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
      initialDueDate: initialDueDate,
      initialStartAt: initialStartAt,
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
    this.initialDueDate,
    this.initialStartAt,
    this.initialMyDay = false,
    this.initialImportant = false,
  });

  final TodoTask? task;
  final String? initialTitle;
  final String? initialListId;
  final DateTime? initialDueDate;
  final DateTime? initialStartAt;
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
  DateTime? _startAt;
  int? _durationMinutes;
  DateTime? _reminderAt;
  RecurrenceRule? _recurrence;
  late List<TaskStep> _steps;
  late List<String> _tags;
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
    _dueAt = task?.dueAt ?? widget.initialDueDate ?? widget.initialStartAt;
    _startAt = task?.startAt ?? widget.initialStartAt;
    _durationMinutes = task?.durationMinutes;
    _reminderAt = task?.reminderAt;
    _recurrence = task?.recurrence;
    _steps = List<TaskStep>.from(task?.steps ?? const <TaskStep>[]);
    _tags = List<String>.from(task?.tags ?? const <String>[]);
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
            startAt: _startAt,
            durationMinutes: _durationMinutes,
            reminderAt: _reminderAt,
            recurrence: _recurrence,
            steps: _steps,
            tags: _tags,
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
            startAt: _startAt == null
                ? null
                : nextDue.copyWith(
                    hour: _startAt!.hour,
                    minute: _startAt!.minute,
                    second: 0,
                    millisecond: 0,
                  ),
            durationMinutes: _durationMinutes,
            reminderAt: nextReminder,
            recurrence: _recurrence,
            steps: _steps
                .map((step) => step.copyWith(isCompleted: false))
                .toList(),
            tags: _tags,
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
          startAt: _startAt,
          durationMinutes: _durationMinutes,
          reminderAt: _reminderAt,
          recurrence: _recurrence,
          steps: _steps,
          tags: _tags,
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
      setState(() {
        _dueAt = picked;
        if (_startAt != null) {
          _startAt = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _startAt!.hour,
            _startAt!.minute,
          );
        }
      });
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

  Future<void> _pickStartTime() async {
    if (_dueAt == null) {
      await _pickDueDate();
      if (_dueAt == null || !mounted) return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: _startAt == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(_startAt!),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startAt = DateTime(
        _dueAt!.year,
        _dueAt!.month,
        _dueAt!.day,
        picked.hour,
        picked.minute,
      );
      _durationMinutes ??= 30;
    });
  }

  Future<void> _pickDuration() async {
    if (_startAt == null) return;
    final options = <int>[15, 30, 45, 60, 90, 120];
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final minutes in options)
              ListTile(
                title: Text(
                    AppLocalizations.of(sheetContext).durationMinutes(minutes)),
                trailing: minutes == (_durationMinutes ?? 30)
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(minutes),
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(AppLocalizations.of(sheetContext).customDuration),
              onTap: () async {
                final controller = TextEditingController(
                    text: (_durationMinutes ?? 30).toString());
                final value = await showDialog<int>(
                  context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(AppLocalizations.of(dialogContext).duration),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        suffixText: AppLocalizations.of(dialogContext).minutes,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(AppLocalizations.of(dialogContext).cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(
                          dialogContext,
                          int.tryParse(controller.text.trim()),
                        ),
                        child: Text(AppLocalizations.of(dialogContext).save),
                      ),
                    ],
                  ),
                );
                controller.dispose();
                if (value != null && value > 0 && sheetContext.mounted) {
                  Navigator.of(sheetContext).pop(value);
                }
              },
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _durationMinutes = selected);
    }
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

  Future<void> _showAddTagDialog() async {
    final textController = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final tag = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addTag),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(
              prefixText: '#',
              hintText: l10n.tagPlaceholder,
            ),
            onSubmitted: (val) {
              Navigator.of(context).pop(val.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(textController.text.trim()),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      },
    );
    textController.dispose();
    if (tag != null && tag.isNotEmpty) {
      final clean = tag.replaceAll('#', '').trim().toLowerCase();
      if (clean.isNotEmpty && !_tags.contains(clean)) {
        setState(() {
          _tags.add(clean);
        });
      }
    }
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
                onReorder: (oldIndex, newIndex) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _steps.removeAt(oldIndex);
                    _steps.insert(newIndex, item);
                  });
                },
                stepController: _stepController,
                stepFocus: _stepFocus,
                onAddStep: _addStepFromInput,
              ),
              const SizedBox(height: 8),
              if (widget.task != null)
                _ActionTile(
                  icon: Icons.timer_outlined,
                  title: l10n.focusMode,
                  subtitle: l10n.focusPomodoro,
                  accent: accent,
                  active: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    showFocusModeSheet(context, task: widget.task!);
                  },
                ),
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
                onClear: _dueAt == null
                    ? null
                    : () => setState(() {
                          _dueAt = null;
                          _startAt = null;
                          _durationMinutes = null;
                        }),
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
                icon: Icons.schedule_rounded,
                title: _startAt == null ? l10n.startTime : l10n.startTime,
                subtitle: _startAt == null
                    ? (_dueAt == null ? l10n.allDay : null)
                    : DateTimeFormatter.timeLabel(_startAt!),
                accent: accent,
                active: _startAt != null,
                onTap: _pickStartTime,
                onClear: _startAt == null
                    ? null
                    : () => setState(() {
                          _startAt = null;
                          _durationMinutes = null;
                        }),
              ),
              _ActionTile(
                icon: Icons.timelapse_rounded,
                title: l10n.duration,
                subtitle: _startAt == null
                    ? l10n.allDay
                    : l10n.durationMinutes(_durationMinutes ?? 30),
                accent: accent,
                active: _startAt != null,
                onTap: _pickDuration,
              ),
              if (_dueAt != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.allDay),
                  value: _startAt == null,
                  activeThumbColor: accent,
                  onChanged: (allDay) => setState(() {
                    if (allDay) {
                      _startAt = null;
                      _durationMinutes = null;
                    } else {
                      _startAt = DateTime(
                        _dueAt!.year,
                        _dueAt!.month,
                        _dueAt!.day,
                        9,
                      );
                      _durationMinutes = 30;
                    }
                  }),
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
              _TagsSection(
                tags: _tags,
                accent: accent,
                onAdd: _showAddTagDialog,
                onRemove: (tag) => setState(() => _tags.remove(tag)),
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
                    prefixIcon: Icon(
                      Icons.notes_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
