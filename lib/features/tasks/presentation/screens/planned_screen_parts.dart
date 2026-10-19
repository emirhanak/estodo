part of 'planned_screen.dart';

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.child,
    this.isCollapsed = false,
    this.onHandleTap,
    this.onHandleVerticalDragUpdate,
    this.onHandleVerticalDragEnd,
  });

  final Widget child;
  final bool isCollapsed;
  final VoidCallback? onHandleTap;
  final GestureDragUpdateCallback? onHandleVerticalDragUpdate;
  final GestureDragEndCallback? onHandleVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final handleLabel =
        isCollapsed ? l10n.plannedHideWeek : l10n.plannedShowWeek;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Semantics(
            button: true,
            label: handleLabel,
            child: GestureDetector(
              key: const ValueKey('planned-sheet-handle'),
              behavior: HitTestBehavior.opaque,
              onTap: onHandleTap,
              onVerticalDragUpdate: onHandleVerticalDragUpdate,
              onVerticalDragEnd: onHandleVerticalDragEnd,
              child: SizedBox(
                width: double.infinity,
                height: 24,
                child: Center(
                  child: Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: isCollapsed
                ? GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragUpdate: onHandleVerticalDragUpdate,
                    onVerticalDragEnd: onHandleVerticalDragEnd,
                    child: child,
                  )
                : child,
          ),
        ],
      ),
    );
  }
}

/// `2 of 5 done · 3 h 30 min` progress line under the headline.
class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.day,
    required this.accent,
    required this.compact,
  });

  final PlannedDay day;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (day.totalCount == 0) {
      return const SizedBox(height: 6);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 20 : 28, 0, compact ? 16 : 24, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${l10n.plannedProgressSummary(day.doneCount, day.totalCount)}'
              '${day.plannedMinutes > 0 ? ' · ${PlannedFormat.duration(l10n, day.plannedMinutes)}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: day.progress),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: scheme.outlineVariant.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Planned tab's own add button: tap starts a habit (default), long-press offers a one-time plan.
class _ComposerButton extends StatefulWidget {
  const _ComposerButton({
    required this.accent,
    required this.onTask,
    required this.onHabit,
  });

  final Color accent;
  final VoidCallback onTask;
  final VoidCallback onHabit;

  @override
  State<_ComposerButton> createState() => _ComposerButtonState();
}

class _ComposerButtonState extends State<_ComposerButton> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          l10n.composerKindTask,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FloatingActionButton.small(
                        heroTag: 'planned-task-fab',
                        backgroundColor: scheme.surfaceContainerLowest,
                        foregroundColor: widget.accent,
                        onPressed: () {
                          setState(() => _expanded = false);
                          widget.onTask();
                        },
                        child: const Icon(Icons.event_available_rounded),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        GestureDetector(
          onLongPress: () => setState(() => _expanded = !_expanded),
          child: FloatingActionButton(
            heroTag: 'planned-compose-fab',
            onPressed: widget.onHabit,
            tooltip: l10n.newTask,
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 220),
              turns: _expanded ? 0.125 : 0,
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ),
      ],
    );
  }
}
