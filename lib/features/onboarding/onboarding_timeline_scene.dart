import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a sample day as an estodo timeline: rows slide in one by one, then
/// the first few get checked off with a light haptic tick each.
class OnboardingTimelineScene extends StatefulWidget {
  const OnboardingTimelineScene({super.key});

  @override
  State<OnboardingTimelineScene> createState() =>
      _OnboardingTimelineSceneState();
}

class _OnboardingTimelineSceneState extends State<OnboardingTimelineScene> {
  static const _rowStep = Duration(milliseconds: 420);
  static const _checkStep = Duration(milliseconds: 650);
  static const _checkedCount = 4;

  int _shown = 0;
  int _checked = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _shown > 0) return;
    if (MediaQuery.of(context).disableAnimations) {
      _shown = _rows.length;
      _checked = _checkedCount;
      return;
    }
    _timer = Timer(const Duration(milliseconds: 400), _tick);
  }

  void _tick() {
    if (!mounted) return;
    if (_shown < _rows.length) {
      HapticFeedback.lightImpact();
      setState(() => _shown++);
      _timer = Timer(_rowStep, _tick);
    } else if (_checked < _checkedCount) {
      HapticFeedback.lightImpact();
      setState(() => _checked++);
      _timer = Timer(_checkStep, _tick);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            isTr
                ? 'Neyin sığdığını gör.\nİçin rahat planla.'
                : 'See what fits.\nPlan with confidence.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
        ),
        Expanded(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, 0.6, 1],
            ).createShader(rect),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _rows.length,
              itemBuilder: (context, i) => _AnimatedRow(
                row: _rows[i],
                isTr: isTr,
                visible: i < _shown,
                checked: i < _checked,
                connectorBelow: i < _rows.length - 1,
                connectorDone: i + 1 < _checked,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedRow extends StatelessWidget {
  const _AnimatedRow({
    required this.row,
    required this.isTr,
    required this.visible,
    required this.checked,
    required this.connectorBelow,
    required this.connectorDone,
  });

  final _Row row;
  final bool isTr;
  final bool visible;
  final bool checked;
  final bool connectorBelow;
  final bool connectorDone;

  static const _capsuleWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final height = row.tall ? 84.0 : 56.0;
    final pale = Color.alphaBlend(
      row.color
          .withValues(alpha: theme.brightness == Brightness.dark ? 0.22 : 0.16),
      scheme.surface,
    );
    const duration = Duration(milliseconds: 380);

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.4),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: Column(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: duration,
                  width: _capsuleWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: checked ? row.color : pale,
                    borderRadius: BorderRadius.circular(_capsuleWidth / 2),
                  ),
                  child: Icon(
                    row.icon,
                    color: checked ? Colors.white : row.color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.time,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: duration,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: checked
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                          decoration:
                              checked ? TextDecoration.lineThrough : null,
                        ),
                        child: Text(isTr ? row.tr : row.en),
                      ),
                    ],
                  ),
                ),
                _CheckDot(color: row.color, checked: checked),
              ],
            ),
            SizedBox(
              height: 14,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(left: _capsuleWidth / 2 - 1),
                  width: 2,
                  color: !connectorBelow
                      ? Colors.transparent
                      : connectorDone
                          ? row.color
                          : scheme.outlineVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.color, required this.checked});

  final Color color;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _Row {
  const _Row(this.time, this.tr, this.en, this.icon, this.color,
      {this.tall = false});

  final String time;
  final String tr;
  final String en;
  final IconData icon;
  final Color color;
  final bool tall;
}

const _rows = <_Row>[
  _Row('06:30', 'Güne başla', 'Rise and shine', Icons.alarm_rounded,
      Color(0xFFF1948A)),
  _Row('07:30', 'Bulaşıkları yıka', 'Do the dishes', Icons.restaurant_rounded,
      Color(0xFFE6B800)),
  _Row('07:45', 'Çöpü çıkar', 'Take out trash', Icons.delete_outline_rounded,
      Color(0xFF6AB04C)),
  _Row('08:30 – 09:15', 'Sabah toplantısı', 'Morning meeting',
      Icons.groups_rounded, Color(0xFF5B8DEF),
      tall: true),
  _Row('09:30', 'Toplantı notlarını hazırla', 'Prep meeting notes',
      Icons.notes_rounded, Color(0xFFE74C3C)),
  _Row('10:30 – 11:15', 'Proje güncellemesi', 'Project update',
      Icons.trending_up_rounded, Color(0xFFE8836B),
      tall: true),
  _Row('11:30 – 12:15', 'Odak zamanı', 'Focus time',
      Icons.center_focus_strong_rounded, Color(0xFF2ECC71),
      tall: true),
];
