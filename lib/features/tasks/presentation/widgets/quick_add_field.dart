import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/task_providers.dart';
import 'task_editor_sheet.dart';

class QuickAddPrefill {
  const QuickAddPrefill({
    this.listId,
    this.isMyDay = false,
    this.isImportant = false,
  });

  final String? listId;
  final bool isMyDay;
  final bool isImportant;
}

class QuickAddField extends ConsumerStatefulWidget {
  const QuickAddField({
    super.key,
    required this.accent,
    this.prefill,
  });

  final Color accent;
  final QuickAddPrefill? prefill;

  @override
  ConsumerState<QuickAddField> createState() => _QuickAddFieldState();
}

class _QuickAddFieldState extends ConsumerState<QuickAddField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final prefill = widget.prefill ?? const QuickAddPrefill();
    await ref.read(taskControllerProvider).createTask(
          title: text,
          listId: prefill.listId,
          isMyDay: prefill.isMyDay,
          isImportant: prefill.isImportant,
        );
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _focused ? widget.accent : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.add_circle_outline_rounded,
              color: _focused ? widget.accent : scheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  hintText: l10n.addTask,
                  filled: false,
                ),
              ),
            ),
            if (_focused)
              IconButton(
                tooltip: l10n.addTask,
                icon: const Icon(Icons.tune_rounded, size: 20),
                onPressed: () {
                  final text = _controller.text.trim();
                  _controller.clear();
                  showTaskEditorSheet(
                    context,
                    initialTitle: text.isEmpty ? null : text,
                    initialListId: widget.prefill?.listId,
                    initialMyDay: widget.prefill?.isMyDay ?? false,
                    initialImportant: widget.prefill?.isImportant ?? false,
                  );
                },
              ),
            IconButton(
              tooltip: l10n.addTask,
              icon: Icon(
                Icons.send_rounded,
                color: _controller.text.trim().isEmpty
                    ? scheme.onSurfaceVariant
                    : widget.accent,
                size: 20,
              ),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
