import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../utils/planned_layout.dart';
import 'planned_format.dart';
import 'planned_mode_glyph.dart';

enum PlannedHeaderAction { smartPlan, importCalendar }

enum PlannedViewMode { day, week, month }

/// Structured-style headline: big day + month + year, a chevron that drops
/// down the month calendar, the Today button, and the G/H/A (D/W/M) mode switch.
class PlannedHeader extends StatelessWidget {
  const PlannedHeader({
    super.key,
    required this.date,
    required this.accent,
    required this.onToday,
    required this.onAction,
    required this.calendarOpen,
    required this.onToggleCalendar,
    this.viewMode = PlannedViewMode.day,
    this.onSelectViewMode,
    this.compact = false,
  });

  final DateTime date;
  final Color accent;
  final VoidCallback onToday;
  final ValueChanged<PlannedHeaderAction> onAction;

  /// Whether the month calendar under the header is open; tapping the title
  /// or its chevron toggles it.
  final bool calendarOpen;
  final VoidCallback onToggleCalendar;
  final PlannedViewMode viewMode;
  final ValueChanged<PlannedViewMode>? onSelectViewMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = PlannedFormat.intlLocale(context);
    final isToday = PlannedLayout.isSameDay(date, DateTime.now());
    final titleSize = compact ? 20.0 : 26.0;
    // On phones the planned tab has no app bar, so the drawer button lives
    // at the start of this row.
    final showMenu = Scaffold.maybeOf(context)?.hasDrawer ?? false;

    final title = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${date.day} ',
            style: TextStyle(color: scheme.onSurface),
          ),
          TextSpan(
            text: '${PlannedFormat.monthYear(date, locale)} ',
            style: TextStyle(color: scheme.onSurface),
          ),
          TextSpan(text: '${date.year}', style: TextStyle(color: accent)),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        fontSize: titleSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.1,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        showMenu ? 4 : (compact ? 14 : 24),
        showMenu ? 6 : 8,
        compact ? 6 : 16,
        4,
      ),
      child: Row(
        children: [
          if (showMenu)
            IconButton(
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: const Icon(Icons.menu_rounded),
              visualDensity: VisualDensity.compact,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      button: true,
                      label: l10n.plannedPickMonth,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: onToggleCalendar,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.25),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: KeyedSubtree(
                              key: ValueKey(
                                '${date.year}-${date.month}-${date.day}',
                              ),
                              child: title,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _CalendarChevron(
                      expanded: calendarOpen,
                      accent: accent,
                      size: titleSize + 2,
                      onTap: onToggleCalendar,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: isToday
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TextButton(
                      onPressed: onToday,
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        l10n.plannedToday,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
          ),
          _ModeSwitch(
            viewMode: calendarOpen ? PlannedViewMode.month : viewMode,
            accent: accent,
            onSelect: (mode) {
              if (onSelectViewMode != null) {
                onSelectViewMode!(mode);
              } else if (mode == PlannedViewMode.month) {
                onToggleCalendar();
              }
            },
          ),
          PopupMenuButton<PlannedHeaderAction>(
            tooltip: l10n.plannedMoreActions,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onSelected: onAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: PlannedHeaderAction.smartPlan,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: Text(l10n.plannedSmartPlan),
                ),
              ),
              PopupMenuItem(
                value: PlannedHeaderAction.importCalendar,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: Text(l10n.plannedImportCalendar),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3-button segmented control with calendar icons containing G/H/A (TR) or D/W/M (EN).
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.viewMode,
    required this.accent,
    required this.onSelect,
  });

  final PlannedViewMode viewMode;
  final Color accent;
  final ValueChanged<PlannedViewMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeOption(
            letter: l10n.plannedDayShort,
            tooltip: l10n.plannedHideWeek,
            selected: viewMode == PlannedViewMode.day,
            accent: accent,
            onTap: () => onSelect(PlannedViewMode.day),
          ),
          _ModeOption(
            letter: l10n.plannedWeekShort,
            tooltip: l10n.plannedShowWeek,
            selected: viewMode == PlannedViewMode.week,
            accent: accent,
            onTap: () => onSelect(PlannedViewMode.week),
          ),
          _ModeOption(
            letter: l10n.plannedMonthShort,
            tooltip: l10n.plannedPickMonth,
            selected: viewMode == PlannedViewMode.month,
            accent: accent,
            onTap: () => onSelect(PlannedViewMode.month),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.letter,
    required this.tooltip,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String letter;
  final String tooltip;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? accent : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? scheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: PlannedModeGlyph(
              letter: letter,
              color: fg,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chevron beside the title that opens and closes the month calendar.
/// Points right when closed and turns down when the calendar is open.
class _CalendarChevron extends StatelessWidget {
  const _CalendarChevron({
    required this.expanded,
    required this.accent,
    required this.size,
    required this.onTap,
  });

  final bool expanded;
  final Color accent;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label =
        expanded ? l10n.plannedHideCalendar : l10n.plannedShowCalendar;
    return Semantics(
      button: true,
      expanded: expanded,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          radius: size,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AnimatedRotation(
              turns: expanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Icon(
                Icons.chevron_right_rounded,
                color: accent,
                size: size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

