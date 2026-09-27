import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../utils/planned_draft.dart';
import '../../../utils/task_icon_catalog.dart';
import '../planned_capsule.dart';

/// The colored composer head: close button, the icon that opens the appearance
/// sheet, and the title field. It carries the task color, so picking a color
/// repaints the whole top of the flow.
class ComposerHeader extends StatelessWidget {
  const ComposerHeader({
    super.key,
    required this.draft,
    required this.controller,
    required this.focusNode,
    required this.onClose,
    required this.onAppearance,
    required this.onTitleChanged,
    required this.onSubmitted,
    this.summary,
    this.kindSwitch,
  });

  final PlannedDraft draft;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClose;
  final VoidCallback onAppearance;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onSubmitted;

  /// Time range shown above the title once the schedule step is reached.
  final String? summary;
  final Widget? kindSwitch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Color(draft.colorValue);
    final foreground = PlannedCapsule.foregroundOn(color);
    final iconKey = draft.iconKey ??
        (TaskIconCatalog.suggestKeys(draft.title, max: 1).firstOrNull ??
            TaskIconCatalog.fallbackKey);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      color: color,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CircleButton(
                  icon: Icons.close_rounded,
                  foreground: foreground,
                  onTap: onClose,
                  tooltip: l10n.cancel,
                ),
                const Spacer(),
                if (kindSwitch != null) kindSwitch!,
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _IconAvatar(
                  iconKey: iconKey,
                  color: color,
                  foreground: foreground,
                  onTap: onAppearance,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        alignment: Alignment.centerLeft,
                        child: summary == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  summary!,
                                  style: TextStyle(
                                    color: foreground.withValues(alpha: 0.75),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: onTitleChanged,
                        onSubmitted: (_) => onSubmitted(),
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        cursorColor: foreground,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.only(bottom: 6),
                          hintText: draft.isHabit
                              ? l10n.composerHabitHint
                              : l10n.composerTitleHint,
                          hintStyle: TextStyle(
                            color: foreground.withValues(alpha: 0.55),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: foreground.withValues(alpha: 0.45),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: foreground, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAvatar extends StatelessWidget {
  const _IconAvatar({
    required this.iconKey,
    required this.color,
    required this.foreground,
    required this.onTap,
  });

  final String iconKey;
  final Color color;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).composerColorAndIcon,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: SizedBox(
          width: 66,
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: foreground.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    TaskIconCatalog.resolve(iconKey),
                    key: ValueKey(iconKey),
                    color: foreground,
                    size: 26,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: foreground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.palette_rounded, size: 13, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.foreground,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color foreground;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: foreground.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: foreground, size: 20),
        ),
      ),
    );
  }
}

/// Plan / habit switch that lives in the header on the first step.
class ComposerKindSwitch extends StatelessWidget {
  const ComposerKindSwitch({
    super.key,
    required this.kind,
    required this.foreground,
    required this.background,
    required this.onChanged,
  });

  final PlannedDraftKind kind;
  final Color foreground;

  /// The header color, used for the label sitting on the selected pill.
  final Color background;
  final ValueChanged<PlannedDraftKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in PlannedDraftKind.values)
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: option == kind ? foreground : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      option == PlannedDraftKind.habit
                          ? Icons.autorenew_rounded
                          : Icons.event_available_rounded,
                      size: 15,
                      color: option == kind ? background : foreground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      option == PlannedDraftKind.habit
                          ? l10n.composerKindHabit
                          : l10n.composerKindTask,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: option == kind ? background : foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
