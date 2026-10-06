import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    if (widget.showUnscheduled && day.habits.isNotEmpty) {
      children.add(
        PlannedHabitSection(
          entries: day.habits,
          accent: widget.accent,
          onOpen: widget.onOpen,
          onToggle: widget.onToggle,
        ),
      );
    }

    final scheduled = day.scheduled;
    var nowInserted = !_isToday;

    if (scheduled.isNotEmpty && scheduled.first.start != null) {
      final dayStart = PlannedLayout.dayOf(day.date).add(
        const Duration(minutes: PlannedLayout.dayStartMinute),
      );
      final free = scheduled.first.start!.difference(dayStart).inMinutes;
      if (free >= PlannedLayout.minGapMinutes) {
        children.add(_gapSlot(dayStart, free));
      }
    }

    for (var i = 0; i < scheduled.length; i++) {
      final entry = scheduled[i];
      final start = entry.start;

      if (!nowInserted && start != null && widget.now.isBefore(start)) {
        nowInserted = true;
        children.add(_nowMarker());
      }

      children.add(
        _EntranceBubble(
          key: ValueKey('planned-enter-${entry.task.id}'),
          delay: Duration(milliseconds: 40 * (i > 8 ? 8 : i)),
          child: PlannedEntryRow(
            key: ValueKey('planned-row-${entry.task.id}'),
            entry: entry,
            now: widget.now,
            gutterWidth: _gutter,
            connectorTop: i > 0,
            connectorBottom: i < scheduled.length - 1,
            onOpen: () => widget.onOpen(entry.task),
            onToggle: () => widget.onToggle(entry.task),
            onDropped:
                start == null ? null : (task) => widget.onSchedule(task, start),
          ),
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
      final dayStart = PlannedLayout.dayOf(day.date).add(
        const Duration(minutes: PlannedLayout.dayStartMinute),
      );
      children.add(_gapSlot(_notBeforeNow(dayStart), null));
      children.add(_emptyDay(l10n));
    } else {
      if (!nowInserted) children.add(_nowMarker());
      final last = scheduled.last.end;
      if (last != null) children.add(_gapSlot(_notBeforeNow(last), null));
    }

    final allScheduledDone =
        scheduled.isNotEmpty && scheduled.every((e) => e.isCompleted);
    if (allScheduledDone) {
      children.add(
        _DayCompletedBanner(
          accent: widget.accent,
          count: scheduled.length,
        ),
      );
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

  /// On today, never suggest adding at a time that has already passed.
  DateTime _notBeforeNow(DateTime start) {
    final now = widget.now;
    if (!PlannedLayout.isSameDay(start, now) || !start.isBefore(now)) {
      return start;
    }
    return PlannedLayout.roundToQuarter(now);
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
          SizedBox(
            width: PlannedCapsule.columnWidth,
            child: Center(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(left: 4, right: 12),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.65),
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
        HapticFeedback.selectionClick();
        setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
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
            // The add button hugs the left edge so the row reads as an
            // action rather than part of the timeline axis.
            child: Row(
              children: [
                const SizedBox(width: 2),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: active ? 44 : 40,
                        height: active ? 44 : 40,
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
                          size: active ? 26 : 24,
                          color: active
                              ? PlannedCapsule.foregroundOn(widget.accent)
                              : widget.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: active
                              ? widget.accent
                              : scheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w600,
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

class _DayCompletedBanner extends StatelessWidget {
  const _DayCompletedBanner({
    required this.accent,
    required this.count,
  });

  final Color accent;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.celebration_rounded, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isTr ? 'Günün Tüm Planları Bitti!' : 'All Plans Completed!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTr
                      ? '$count planlanan görevin hepsi tamamlandı. Harika!'
                      : 'All $count scheduled tasks finished. Great job!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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

/// One-shot entrance: rows pop in with a soft scale, slide and fade, staggered
/// by [delay].
class _EntranceBubble extends StatefulWidget {
  const _EntranceBubble({super.key, required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_EntranceBubble> createState() => _EntranceBubbleState();
}

class _EntranceBubbleState extends State<_EntranceBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: _controller.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t)),
            child: Transform.scale(
              scale: 0.92 + 0.08 * t,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
