import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../utils/planned_layout.dart';
import 'planned_format.dart';

enum PlannedViewMode { day, week }

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
    this.compact = false,
  });

  final DateTime date;
  final PlannedViewMode mode;
  final Color accent;
  final ValueChanged<PlannedViewMode> onModeChanged;
  final VoidCallback onPickDate;
  final VoidCallback onToday;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = PlannedFormat.intlLocale(context);
    final isToday = PlannedLayout.isSameDay(date, DateTime.now());
    final titleSize = compact ? 26.0 : 32.0;

    final title = Text.rich(
      TextSpan(
        children: [
          if (mode == PlannedViewMode.day)
            TextSpan(
              text: '${date.day}. ',
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
        letterSpacing: -0.8,
        height: 1.1,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 18 : 24, 8, compact ? 10 : 16, 4),
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
                    horizontal: 6,
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
                      Padding(
                        padding: const EdgeInsets.only(left: 2, top: 4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: accent,
                          size: titleSize - 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
        ],
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
    final segmentWidth = compact ? 44.0 : 102.0;
    const height = 38.0;

    return Container(
      height: height,
      width: segmentWidth * 2,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: mode == PlannedViewMode.day
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: segmentWidth,
              height: height,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
                icon: Icons.view_agenda_rounded,
                label: l10n.plannedDayView,
                selected: mode == PlannedViewMode.day,
                onTap: () => onChanged(PlannedViewMode.day),
              ),
              _segment(
                context,
                width: segmentWidth,
                icon: Icons.calendar_view_week_rounded,
                label: l10n.plannedWeekView,
                selected: mode == PlannedViewMode.week,
                onTap: () => onChanged(PlannedViewMode.week),
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
    required IconData icon,
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
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              if (!compact) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
