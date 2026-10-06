import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../utils/planned_layout.dart';
import 'planned_format.dart';

enum PlannedHeaderAction { smartPlan, importCalendar }

/// Structured-style headline: big day + month and a chevron that drops
/// down the month calendar.
class PlannedHeader extends StatelessWidget {
  const PlannedHeader({
    super.key,
    required this.date,
    required this.accent,
    required this.onToday,
    required this.onAction,
    required this.calendarOpen,
    required this.onToggleCalendar,
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
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = PlannedFormat.intlLocale(context);
    final isToday = PlannedLayout.isSameDay(date, DateTime.now());
    final titleSize = compact ? 21.0 : 28.0;
    // On phones the planned tab has no app bar, so the drawer button lives
    // at the start of this row.
    final showMenu = Scaffold.maybeOf(context)?.hasDrawer ?? false;
    // Phones have little room once the "Today" button appears, so the
    // current year is implied there.
    final showYear = !compact || date.year != DateTime.now().year;

    final title = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${date.day} ',
            style: TextStyle(color: scheme.onSurface),
          ),
          TextSpan(
            text: showYear
                ? '${PlannedFormat.monthYear(date, locale)} '
                : PlannedFormat.monthYear(date, locale),
            style: TextStyle(color: scheme.onSurface),
          ),
          if (showYear)
            TextSpan(text: '${date.year}', style: TextStyle(color: accent)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: titleSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.1,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        showMenu ? 4 : (compact ? 16 : 24),
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
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Semantics(
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
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
                          ],
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
          const SizedBox(width: 4),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: isToday
                ? const SizedBox.shrink()
                : compact
                    // A text button would squeeze the date title on phones.
                    ? IconButton(
                        tooltip: l10n.plannedToday,
                        onPressed: onToday,
                        color: accent,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.today_rounded),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: TextButton(
                          onPressed: onToday,
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(l10n.plannedToday),
                        ),
                      ),
          ),
          PopupMenuButton<PlannedHeaderAction>(
            tooltip: l10n.plannedMoreActions,
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
