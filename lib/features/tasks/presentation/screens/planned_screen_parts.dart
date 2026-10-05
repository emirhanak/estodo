part of 'planned_screen.dart';

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// `2 of 5 done · 3 h 30 min` progress line under the headline, plus streak badge.
class _SummaryLine extends ConsumerWidget {
  const _SummaryLine({
    required this.day,
    required this.accent,
    required this.compact,
  });

  final PlannedDay day;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final streak = ref.watch(streakProvider);

    if (day.totalCount == 0 && streak.currentStreak == 0) {
      return const SizedBox(height: 10);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 24 : 30, 0, compact ? 18 : 24, 8),
      child: Row(
        children: [
          if (streak.currentStreak > 0) ...[
            Tooltip(
              message: l10n.streakActive(streak.currentStreak),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.deepOrange.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3.5),
                    Text(
                      '${streak.currentStreak}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (day.totalCount > 0) ...[
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
                    backgroundColor:
                        scheme.outlineVariant.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }
}

/// Planned tab's own add button: tap plans, the small satellite starts a habit.
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
                          l10n.composerKindHabit,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FloatingActionButton.small(
                        heroTag: 'planned-habit-fab',
                        backgroundColor: scheme.surfaceContainerLowest,
                        foregroundColor: widget.accent,
                        onPressed: () {
                          setState(() => _expanded = false);
                          widget.onHabit();
                        },
                        child: const Icon(Icons.autorenew_rounded),
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
            onPressed: widget.onTask,
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
