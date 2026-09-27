import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_theme.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/recurrence_rule.dart';
import '../../../utils/task_icon.dart';
import '../../../utils/task_icon_catalog.dart';
import '../planned_capsule.dart';

/// What the icon sheet hands back: both the glyph and the color are picked in
/// the same place, the way Structured does it.
class ComposerAppearance {
  const ComposerAppearance({required this.iconKey, required this.colorValue});

  final String? iconKey;
  final int colorValue;
}

/// Wrapper so "cleared" is distinguishable from "cancelled".
class ComposerValue<T> {
  const ComposerValue(this.value);

  final T? value;
}

Future<ComposerAppearance?> showComposerAppearanceSheet(
  BuildContext context, {
  required String? iconKey,
  required int colorValue,
  required String title,
}) {
  return showModalBottomSheet<ComposerAppearance>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AppearanceSheet(
      iconKey: iconKey,
      colorValue: colorValue,
      title: title,
    ),
  );
}

class _AppearanceSheet extends StatefulWidget {
  const _AppearanceSheet({
    required this.iconKey,
    required this.colorValue,
    required this.title,
  });

  final String? iconKey;
  final int colorValue;
  final String title;

  @override
  State<_AppearanceSheet> createState() => _AppearanceSheetState();
}

class _AppearanceSheetState extends State<_AppearanceSheet> {
  late String? _iconKey = widget.iconKey;
  late int _color = widget.colorValue;
  TaskIconCategory? _category;
  String _query = '';

  void _emit() => Navigator.of(context).pop(
        ComposerAppearance(iconKey: _iconKey, colorValue: _color),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final suggestions = TaskIcons.suggestKeysForTitle(widget.title);
    final entries = _query.isNotEmpty
        ? TaskIconCatalog.search(_query)
        : _category == null
            ? TaskIconCatalog.entries
            : TaskIconCatalog.byCategory(_category!);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.composerColorAndIcon,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: _emit,
                  icon: const Icon(Icons.check_rounded),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: ListPalette.colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final value = ListPalette.colors[index];
                final selected = value == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(value),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: scheme.onSurface, width: 2.5)
                          : null,
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: PlannedCapsule.foregroundOn(Color(value)),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          if (suggestions.isNotEmpty && _query.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                l10n.composerSuggestions,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _IconBubble(
                  iconKey: suggestions[index],
                  color: Color(_color),
                  selected: suggestions[index] == _iconKey,
                  onTap: () => setState(() => _iconKey = suggestions[index]),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                hintText: l10n.composerSearchIcons,
              ),
            ),
          ),
          if (_query.isEmpty)
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: TaskIconCategory.values.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CategoryChip(
                      label: l10n.composerCategoryAll,
                      selected: _category == null,
                      color: Color(_color),
                      onTap: () => setState(() => _category = null),
                    );
                  }
                  final category = TaskIconCategory.values[index - 1];
                  return _CategoryChip(
                    label: _categoryLabel(l10n, category),
                    selected: _category == category,
                    color: Color(_color),
                    onTap: () => setState(() => _category = category),
                  );
                },
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 68,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _IconBubble(
                  iconKey: entry.key,
                  color: Color(_color),
                  selected: entry.key == _iconKey,
                  onTap: () => setState(() => _iconKey = entry.key),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _categoryLabel(AppLocalizations l10n, TaskIconCategory category) {
  return switch (category) {
    TaskIconCategory.general => l10n.composerCategoryGeneral,
    TaskIconCategory.work => l10n.composerCategoryWork,
    TaskIconCategory.health => l10n.composerCategoryHealth,
    TaskIconCategory.food => l10n.composerCategoryFood,
    TaskIconCategory.home => l10n.composerCategoryHome,
    TaskIconCategory.learning => l10n.composerCategoryLearning,
    TaskIconCategory.social => l10n.composerCategorySocial,
    TaskIconCategory.travel => l10n.composerCategoryTravel,
    TaskIconCategory.leisure => l10n.composerCategoryLeisure,
    TaskIconCategory.money => l10n.composerCategoryMoney,
  };
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.iconKey,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? color : scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          TaskIconCatalog.resolve(iconKey),
          size: 24,
          color: selected
              ? PlannedCapsule.foregroundOn(color)
              : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.16)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(19),
          border: selected ? Border.all(color: color, width: 1.4) : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? color : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

/// Bottom sheet mirroring Structured's Repeat card.
Future<ComposerValue<RecurrenceRule>?> showComposerRepeatSheet(
  BuildContext context, {
  required RecurrenceRule? rule,
  required DateTime startDate,
  required Color color,
}) {
  return showModalBottomSheet<ComposerValue<RecurrenceRule>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _RepeatSheet(
      rule: rule,
      startDate: startDate,
      color: color,
    ),
  );
}

class _RepeatSheet extends StatefulWidget {
  const _RepeatSheet({
    required this.rule,
    required this.startDate,
    required this.color,
  });

  final RecurrenceRule? rule;
  final DateTime startDate;
  final Color color;

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<_RepeatSheet> {
  late RecurrenceRule? _rule = widget.rule;

  static const _options = <RecurrenceFrequency?>[
    null,
    RecurrenceFrequency.daily,
    RecurrenceFrequency.weekly,
    RecurrenceFrequency.monthly,
  ];

  void _select(RecurrenceFrequency? frequency) {
    setState(() {
      if (frequency == null) {
        _rule = null;
        return;
      }
      _rule = RecurrenceRule(
        frequency: frequency,
        interval: _rule?.interval ?? 1,
        weekdays: frequency == RecurrenceFrequency.weekly
            ? (_rule?.weekdays.isNotEmpty ?? false)
                ? _rule!.weekdays
                : [widget.startDate.weekday]
            : const <int>[],
        until: _rule?.until,
      );
    });
  }

  void _toggleWeekday(int weekday) {
    final rule = _rule;
    if (rule == null) return;
    final days = rule.weekdays.toSet();
    if (!days.remove(weekday)) days.add(weekday);
    if (days.isEmpty) days.add(weekday);
    setState(() {
      _rule = rule.copyWith(weekdays: days.toList()..sort());
    });
  }

  Future<void> _pickEnd() async {
    final rule = _rule;
    if (rule == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: rule.until ?? widget.startDate.add(const Duration(days: 30)),
      firstDate: widget.startDate,
      lastDate: DateTime(widget.startDate.year + 5),
    );
    if (picked == null) return;
    setState(() => _rule = rule.copyWith(until: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rule = _rule;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.composerRepeat,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context)
                    .pop(ComposerValue<RecurrenceRule>(_rule)),
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                for (final option in _options)
                  Expanded(
                    child: _SegmentButton(
                      label: _frequencyLabel(l10n, option),
                      selected: option == null
                          ? rule == null
                          : rule?.frequency == option,
                      color: widget.color,
                      onTap: () => _select(option),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: rule == null
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      _IntervalRow(
                        rule: rule,
                        color: widget.color,
                        onChanged: (interval) => setState(
                          () => _rule = rule.copyWith(interval: interval),
                        ),
                      ),
                      if (rule.frequency == RecurrenceFrequency.weekly) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (var day = 1; day <= 7; day++)
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: _WeekdayChip(
                                    weekday: day,
                                    selected: rule.weekdays.contains(day),
                                    color: widget.color,
                                    onTap: () => _toggleWeekday(day),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      _SheetRow(
                        label: l10n.composerRepeatStart,
                        value: _shortDate(widget.startDate),
                        onTap: null,
                      ),
                      const SizedBox(height: 8),
                      _SheetRow(
                        label: rule.until == null
                            ? l10n.composerSetEndDate
                            : l10n.composerRepeatUntil(
                                _shortDate(rule.until!),
                              ),
                        value: rule.until == null ? null : l10n.composerRemove,
                        onTap: rule.until == null
                            ? _pickEnd
                            : () => setState(
                                  () => _rule = rule.copyWith(until: null),
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rule.until == null
                            ? l10n.composerRepeatForever
                            : l10n.composerRepeatUntil(
                                _shortDate(rule.until!),
                              ),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

String _frequencyLabel(AppLocalizations l10n, RecurrenceFrequency? frequency) {
  return switch (frequency) {
    null => l10n.composerRepeatOnce,
    RecurrenceFrequency.daily => l10n.composerRepeatDaily,
    RecurrenceFrequency.weekly => l10n.composerRepeatWeekly,
    RecurrenceFrequency.monthly => l10n.composerRepeatMonthly,
    RecurrenceFrequency.weekdays => l10n.composerRepeatWeekdays,
    RecurrenceFrequency.yearly => l10n.composerRepeatYearly,
  };
}

String _shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? PlannedCapsule.foregroundOn(color)
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _IntervalRow extends StatelessWidget {
  const _IntervalRow({
    required this.rule,
    required this.color,
    required this.onChanged,
  });

  final RecurrenceRule rule;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = switch (rule.frequency) {
      RecurrenceFrequency.daily => l10n.composerEveryDays(rule.interval),
      RecurrenceFrequency.monthly => l10n.composerEveryMonths(rule.interval),
      _ => l10n.composerEveryWeeks(rule.interval),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed:
                rule.interval > 1 ? () => onChanged(rule.interval - 1) : null,
            icon: const Icon(Icons.remove_rounded),
            color: color,
          ),
          SizedBox(
            height: 24,
            child: VerticalDivider(color: scheme.outlineVariant, width: 1),
          ),
          IconButton(
            onPressed:
                rule.interval < 12 ? () => onChanged(rule.interval + 1) : null,
            icon: const Icon(Icons.add_rounded),
            color: color,
          ),
        ],
      ),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.weekday,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final int weekday;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labels = MaterialLocalizations.of(context).narrowWeekdays;
    // narrowWeekdays starts at Sunday; DateTime.monday == 1.
    final label = labels[weekday % 7];
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected
                    ? PlannedCapsule.foregroundOn(color)
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.label, required this.value, this.onTap});

  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

/// Duration sheet with the preset chips and an hour/minute wheel.
Future<int?> showComposerDurationSheet(
  BuildContext context, {
  required int minutes,
  required Color color,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _DurationSheet(minutes: minutes, color: color),
  );
}

class _DurationSheet extends StatefulWidget {
  const _DurationSheet({required this.minutes, required this.color});

  final int minutes;
  final Color color;

  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  late int _minutes = widget.minutes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hours = _minutes ~/ 60;
    final rest = _minutes % 60;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.composerDuration,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(_minutes),
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: _NumberWheel(
                    value: hours,
                    max: 12,
                    suffix: l10n.composerHoursUnit,
                    color: widget.color,
                    onChanged: (value) =>
                        setState(() => _minutes = value * 60 + rest),
                  ),
                ),
                Expanded(
                  child: _NumberWheel(
                    value: rest,
                    max: 55,
                    step: 5,
                    suffix: l10n.composerMinutesUnit,
                    color: widget.color,
                    onChanged: (value) =>
                        setState(() => _minutes = hours * 60 + value),
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

class _NumberWheel extends StatelessWidget {
  const _NumberWheel({
    required this.value,
    required this.max,
    required this.suffix,
    required this.color,
    required this.onChanged,
    this.step = 1,
  });

  final int value;
  final int max;
  final int step;
  final String suffix;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final count = max ~/ step + 1;
    return ListWheelScrollView.useDelegate(
      controller: FixedExtentScrollController(initialItem: value ~/ step),
      itemExtent: 40,
      diameterRatio: 2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) => onChanged(index * step),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          final selected = index * step == value;
          return Center(
            child: Text(
              '${index * step} $suffix',
              style: TextStyle(
                fontSize: selected ? 18 : 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}
