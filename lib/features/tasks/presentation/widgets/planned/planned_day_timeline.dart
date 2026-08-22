import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/todo_task.dart';
import '../../utils/planned_layout.dart';
import 'planned_capsule.dart';
import 'planned_entry_row.dart';
import 'planned_format.dart';
import 'planned_unscheduled.dart';

/// The vertical day timeline: capsules sized by duration, free slots between
/// them and a live "now" marker.
class PlannedDayTimeline extends StatefulWidget {
  const PlannedDayTimeline({
    super.key,
    required this.day,
    required this.now,
    required this.accent,
    required this.onOpen,
    required this.onToggle,
    required this.onAddAt,
    required this.onSchedule,
    this.showUnscheduled = true,
    this.horizontalPadding = 12,
    this.maxContentWidth = double.infinity,
  });

  final PlannedDay day;
  final DateTime now;
  final Color accent;
  final void Function(TodoTask task) onOpen;
  final void Function(TodoTask task) onToggle;
  final void Function(DateTime start) onAddAt;
  final void Function(TodoTask task, DateTime start) onSchedule;
  final bool showUnscheduled;
  final double horizontalPadding;

  /// Keeps the timeline readable on iPad-sized panes.
  final double maxContentWidth;

  @override
  State<PlannedDayTimeline> createState() => _PlannedDayTimelineState();
}

class _PlannedDayTimelineState extends State<PlannedDayTimeline>
    with SingleTickerProviderStateMixin {
  static const _gutter = 52.0;

  late final AnimationController _stagger = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  bool get _isToday => PlannedLayout.isSameDay(widget.day.date, widget.now);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final day = widget.day;
    final children = <Widget>[];

    if (widget.showUnscheduled && day.unscheduled.isNotEmpty) {
      children.add(
        PlannedUnscheduledStrip(
          entries: day.unscheduled,
          accent: widget.accent,
          onOpen: widget.onOpen,
        ),
      );
    }

    final scheduled = day.scheduled;
    var nowInserted = !_isToday;

    for (var i = 0; i < scheduled.length; i++) {
      final entry = scheduled[i];
      final start = entry.start;

      if (!nowInserted && start != null && widget.now.isBefore(start)) {
        nowInserted = true;
        children.add(_nowMarker());
      }

      children.add(
        PlannedEntryRow(
          key: ValueKey('planned-row-${entry.task.id}'),
          entry: entry,
          now: widget.now,
          gutterWidth: _gutter,
          connectorTop: i > 0,
          connectorBottom: i < scheduled.length - 1,
          onOpen: () => widget.onOpen(entry.task),
          onToggle: () => widget.onToggle(entry.task),
        ),
      );

      final end = entry.end;
      final next = i + 1 < scheduled.length ? scheduled[i + 1].start : null;
      if (end != null && next != null) {
        final free = next.difference(end).inMinutes;
        if (free >= PlannedLayout.minGapMinutes) {
          if (!nowInserted &&
              widget.now.isAfter(end) &&
              widget.now.isBefore(next)) {
            nowInserted = true;
            children.add(_nowMarker());
          }
          children.add(_gapSlot(end, free));
        }
      }
    }

    if (scheduled.isEmpty) {
      children.add(_emptyDay(l10n));
    } else {
      if (!nowInserted) children.add(_nowMarker());
      final last = scheduled.last.end;
      if (last != null) children.add(_gapSlot(last, null));
    }

    if (day.completed.isNotEmpty) {
      children.add(
        PlannedCompletedSection(
          entries: day.completed,
          accent: widget.accent,
          onOpen: widget.onOpen,
          onToggle: widget.onToggle,
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(
            widget.horizontalPadding,
            6,
            widget.horizontalPadding,
            160,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: children.length,
          itemBuilder: (context, index) => _StaggerIn(
            controller: _stagger,
            index: index,
            child: children[index],
          ),
        ),
      ),
    );
  }

  Widget _nowMarker() {
    return _NowMarker(
      now: widget.now,
      accent: widget.accent,
      gutterWidth: _gutter,
    );
  }

  Widget _gapSlot(DateTime start, int? minutes) {
    return _GapSlot(
      start: start,
      minutes: minutes,
      accent: widget.accent,
      gutterWidth: _gutter,
      onTap: () => widget.onAddAt(start),
      onDropped: (task) => widget.onSchedule(task, start),
    );
  }

  Widget _emptyDay(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final base = PlannedLayout.dayOf(widget.day.date);
    final suggested = _isToday
        ? PlannedLayout.roundToQuarter(widget.now)
        : base.add(const Duration(minutes: PlannedLayout.dayStartMinute + 120));

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: widget.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 38,
              color: widget.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.plannedEmptyDayTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.plannedEmptyDayBody,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => widget.onAddAt(suggested),
            style: FilledButton.styleFrom(
              backgroundColor: widget.accent,
              foregroundColor: PlannedCapsule.foregroundOn(widget.accent),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.newTask),
          ),
        ],
      ),
    );
  }
}

/// Fades and lifts timeline items in, one shortly after the other.
class _StaggerIn extends StatelessWidget {
  const _StaggerIn({
    required this.controller,
    required this.index,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final begin = (index * 0.05).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, (begin + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _NowMarker extends StatefulWidget {
  const _NowMarker({
    required this.now,
    required this.accent,
    required this.gutterWidth,
  });

  final DateTime now;
  final Color accent;
  final double gutterWidth;

  @override
  State<_NowMarker> createState() => _NowMarkerState();
}

class _NowMarkerState extends State<_NowMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: widget.gutterWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                PlannedFormat.time(widget.now),
                textAlign: TextAlign.end,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: widget.accent,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          FadeTransition(
            opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(left: 4, right: 12),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GapSlot extends StatefulWidget {
  const _GapSlot({
    required this.start,
    required this.minutes,
    required this.accent,
    required this.gutterWidth,
    required this.onTap,
    required this.onDropped,
  });

  final DateTime start;
  final int? minutes;
  final Color accent;
  final double gutterWidth;
  final VoidCallback onTap;
  final void Function(TodoTask task) onDropped;

  @override
  State<_GapSlot> createState() => _GapSlotState();
}

class _GapSlotState extends State<_GapSlot> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = widget.minutes == null
        ? l10n.plannedAddAt(PlannedFormat.time(widget.start))
        : l10n.plannedFreeMinutes(widget.minutes!);

    return DragTarget<TodoTask>(
      onWillAcceptWithDetails: (_) {
        setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _hovering = false);
        widget.onDropped(details.data);
      },
      builder: (context, candidate, __) {
        final active = _hovering || candidate.isNotEmpty;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? widget.accent.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                SizedBox(width: widget.gutterWidth),
                SizedBox(
                  width: PlannedCapsule.columnWidth,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: active ? 30 : 24,
                      height: active ? 30 : 24,
                      decoration: BoxDecoration(
                        color: active
                            ? widget.accent
                            : scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.accent.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: active ? 18 : 14,
                        color: active
                            ? PlannedCapsule.foregroundOn(widget.accent)
                            : widget.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: active
                              ? widget.accent
                              : scheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
