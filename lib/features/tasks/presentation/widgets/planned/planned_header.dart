import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../utils/planned_layout.dart';
import 'planned_format.dart';
import 'planned_mode_glyph.dart';

enum PlannedViewMode { day, week, month }

enum PlannedHeaderAction { smartPlan, importCalendar }

/// Structured-style headline: big day + month, accent year, and the
/// day / week switch.
class PlannedHeader extends StatelessWidget {
  const PlannedHeader({
    super.key,
    required this.date,
    required this.mode,
    required this.accent,
    required this.onModeChanged,
    required this.onPickDate,
    required this.onToday,
    required this.onAction,
    this.weekExpanded,
    this.onToggleWeek,
    this.compact = false,
  });

  final DateTime date;
  final PlannedViewMode mode;
  final Color accent;
  final ValueChanged<PlannedViewMode> onModeChanged;
  final VoidCallback onPickDate;
  final VoidCallback onToday;
  final ValueChanged<PlannedHeaderAction> onAction;

  /// When [onToggleWeek] is set, the chevron next to the title collapses and
  /// expands the week strip instead of being part of the date button.
  final bool? weekExpanded;
  final VoidCallback? onToggleWeek;
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

    final title = Text.rich(
      TextSpan(
        children: [
          if (mode == PlannedViewMode.day)
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
                      onTap: onPickDate,
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
                                    '${mode.name}-${date.year}-${date.month}-${date.day}',
                                  ),
                                  child: title,
                                ),
                              ),
                            ),
                            if (onToggleWeek == null)
                              Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: accent,
                                  size: titleSize - 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (onToggleWeek != null)
                  _WeekChevron(
                    expanded: weekExpanded ?? false,
                    accent: accent,
                    size: titleSize + 2,
                    onTap: onToggleWeek!,
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
          _ModeSwitch(
            mode: mode,
            accent: accent,
            compact: compact,
            onChanged: onModeChanged,
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

/// Chevron beside the title that collapses and expands the week strip.
/// Points right when closed and turns down when the strip is open.
class _WeekChevron extends StatelessWidget {
  const _WeekChevron({
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
    final label = expanded ? l10n.plannedHideWeek : l10n.plannedShowWeek;
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

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.mode,
    required this.accent,
    required this.compact,
    required this.onChanged,
  });

  final PlannedViewMode mode;
  final Color accent;
  final bool compact;
  final ValueChanged<PlannedViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final segmentWidth = compact ? 42.0 : 80.0;
    const outerHeight = 38.0;
    const padding = 3.0;
    const innerHeight = outerHeight - (padding * 2);

    return Container(
      height: outerHeight,
      width: segmentWidth * 3 + (padding * 2),
      padding: const EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(outerHeight / 2),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: switch (mode) {
              PlannedViewMode.day => Alignment.centerLeft,
              PlannedViewMode.week => Alignment.center,
              PlannedViewMode.month => Alignment.centerRight,
            },
            child: Container(
              width: segmentWidth,
              height: innerHeight,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(innerHeight / 2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.22),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _segment(
                context,
                width: segmentWidth,
                shortLabel: l10n.plannedDayShort,
                label: l10n.plannedDayView,
                selected: mode == PlannedViewMode.day,
                onTap: () => onChanged(PlannedViewMode.day),
              ),
              _segment(
                context,
                width: segmentWidth,
                shortLabel: l10n.plannedWeekShort,
                label: l10n.plannedWeekView,
                selected: mode == PlannedViewMode.week,
                onTap: () => onChanged(PlannedViewMode.week),
              ),
              _segment(
                context,
                width: segmentWidth,
                shortLabel: l10n.plannedMonthShort,
                label: l10n.plannedMonthView,
                selected: mode == PlannedViewMode.month,
                onTap: () => onChanged(PlannedViewMode.month),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required double width,
    required String shortLabel,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            // A calendar page with the view's letter (G/H/A, D/W/M); wider
            // layouts add the full word next to it.
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: foreground),
              duration: const Duration(milliseconds: 200),
              builder: (context, color, _) {
                final tint = color ?? foreground;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PlannedModeGlyph(
                      letter: shortLabel,
                      color: tint,
                      size: compact ? 26 : 22,
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: tint,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
