import 'package:estodo/features/tasks/presentation/utils/task_icon_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

String? _best(String title) {
  final keys = TaskIconCatalog.suggestKeys(title, max: 1);
  return keys.isEmpty ? null : keys.first;
}

void main() {
  test('running titles get the runner, with or without Turkish letters', () {
    expect(_best('Koşu'), 'run');
    expect(_best('Kosu'), 'run');
    expect(_best('Sabah koşusu'), 'run');
    expect(_best('Kosu 1 saat yarin 08:00'), 'run');
  });

  test('water titles still get the water drop', () {
    expect(_best('Su iç'), 'water');
  });
}
