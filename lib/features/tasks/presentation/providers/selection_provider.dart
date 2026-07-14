import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskSelectionController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  bool get isActive => state.isNotEmpty;

  void toggle(String id) {
    final next = Set<String>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
  }

  void clear() {
    if (state.isEmpty) return;
    state = const <String>{};
  }

  void replaceAll(Iterable<String> ids) {
    state = ids.toSet();
  }
}

final taskSelectionProvider =
    NotifierProvider<TaskSelectionController, Set<String>>(
  TaskSelectionController.new,
);
