import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../planned_capsule.dart';

/// Structured's signature time picker: a wheel of start slots where the
/// selected row shows the whole block, `09:00 – 09:30`.
class ComposerTimeWheel extends StatefulWidget {
  const ComposerTimeWheel({
    super.key,
    required this.startMinuteOfDay,
    required this.durationMinutes,
    required this.color,
    required this.onChanged,
    this.stepMinutes = 15,
  });

  final int startMinuteOfDay;
  final int durationMinutes;
  final Color color;
  final ValueChanged<int> onChanged;
  final int stepMinutes;

  @override
  State<ComposerTimeWheel> createState() => _ComposerTimeWheelState();
}

class _ComposerTimeWheelState extends State<ComposerTimeWheel> {
  static const _itemExtent = 46.0;

  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(
          initialItem: _indexOf(widget.startMinuteOfDay));

  int get _slots => (24 * 60) ~/ widget.stepMinutes;

  int _indexOf(int minute) =>
      (minute ~/ widget.stepMinutes).clamp(0, _slots - 1);

  @override
  void didUpdateWidget(covariant ComposerTimeWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _indexOf(widget.startMinuteOfDay);
    if (_controller.hasClients && _controller.selectedItem != target) {
      _controller.animateToItem(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _label(int minute) {
    final hour = (minute ~/ 60) % 24;
    final rest = minute % 60;
    return '${hour.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedIndex = _indexOf(widget.startMinuteOfDay);

    return SizedBox(
      height: _itemExtent * 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: _itemExtent,
            diameterRatio: 2.4,
            perspective: 0.002,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              HapticFeedback.selectionClick();
              widget.onChanged(index * widget.stepMinutes);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _slots,
              builder: (context, index) {
                final minute = index * widget.stepMinutes;
                final selected = index == selectedIndex;
                final end = minute + widget.durationMinutes;
                return Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 18 : 10,
                      vertical: selected ? 8 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? widget.color : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      selected
                          ? '${_label(minute)} – ${_label(end)}'
                          : _label(minute),
                      style: TextStyle(
                        fontSize: selected ? 16 : 14,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                        color: selected
                            ? PlannedCapsule.foregroundOn(widget.color)
                            : scheme.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Fade the rows that scroll out of the focus band.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.surfaceContainerLowest,
                      scheme.surfaceContainerLowest.withValues(alpha: 0),
                      scheme.surfaceContainerLowest.withValues(alpha: 0),
                      scheme.surfaceContainerLowest,
                    ],
                    stops: const [0, 0.28, 0.72, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
