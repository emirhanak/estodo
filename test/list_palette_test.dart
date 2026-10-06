import 'package:estodo/features/tasks/presentation/utils/list_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('palette colors are all different', () {
    expect(ListPalette.colors.toSet().length, ListPalette.colors.length);
  });

  test('the first list gets the first palette color', () {
    expect(ListPalette.nextDefault(const []), ListPalette.colors.first);
  });

  test('each new list gets a color no other list uses', () {
    final used = <int>[];
    for (var i = 0; i < ListPalette.colors.length; i++) {
      final next = ListPalette.nextDefault(used);
      expect(used, isNot(contains(next)));
      used.add(next);
    }
    expect(used.toSet().length, ListPalette.colors.length);
  });

  test('skips colors the user already picked by hand', () {
    final second = ListPalette.colors[1];
    expect(
      ListPalette.nextDefault([ListPalette.colors.first, second]),
      ListPalette.colors[2],
    );
    expect(ListPalette.nextDefault([second]), ListPalette.colors.first);
  });

  test('picks the least used color once every color is taken', () {
    final all = [...ListPalette.colors, ListPalette.colors.first];
    expect(ListPalette.nextDefault(all), ListPalette.colors[1]);
  });

  test('ignores custom colors that are not in the palette', () {
    expect(
        ListPalette.nextDefault(const [0xFF123456]), ListPalette.colors.first);
  });
}
