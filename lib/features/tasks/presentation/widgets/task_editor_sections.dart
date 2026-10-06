part of 'task_editor_sheet.dart';

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
    required this.onReorder,
    required this.stepController,
    required this.stepFocus,
    required this.onAddStep,
  });

  final List<TaskStep> steps;
  final Color accent;
  final ValueChanged<TaskStep> onToggle;
  final ValueChanged<TaskStep> onRemove;
  final void Function(TaskStep step, String newTitle) onRename;
  final void Function(int oldIndex, int newIndex) onReorder;
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
          if (steps.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: steps.length,
              // ignore: deprecated_member_use
              onReorder: onReorder,
              itemBuilder: (context, index) {
                final step = steps[index];
                return Padding(
                  key: ValueKey('step-${step.id}'),
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: 18,
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      AnimatedCheckCircle(
                        value: step.isCompleted,
                        color: accent,
                        size: 20,
                        onChanged: (_) => onToggle(step),
                      ),
                      const SizedBox(width: 8),
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
                );
              },
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
                      hintStyle: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
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
                tooltip: Localizations.localeOf(context).languageCode == 'tr'
                    ? 'Temizle'
                    : 'Clear',
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

class _TagsSection extends StatelessWidget {
  const _TagsSection({
    required this.tags,
    required this.accent,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> tags;
  final Color accent;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label_outline_rounded,
                  size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                l10n.tags,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final tag in tags)
                InputChip(
                  label: Text('#$tag'),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSecondaryContainer,
                  ),
                  backgroundColor:
                      scheme.secondaryContainer.withValues(alpha: 0.5),
                  deleteIconColor:
                      scheme.onSecondaryContainer.withValues(alpha: 0.7),
                  onDeleted: () => onRemove(tag),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ActionChip(
                avatar: Icon(Icons.add_rounded, size: 16, color: accent),
                label: Text(l10n.addTag),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
                backgroundColor: accent.withValues(alpha: 0.08),
                side: BorderSide(color: accent.withValues(alpha: 0.2)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
