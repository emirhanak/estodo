/// Colors offered for lists (the planner's categories).
///
/// Ordered so that consecutive defaults look clearly different, which keeps
/// categories distinguishable on the planner without the user picking colors.
abstract final class ListPalette {
  static const colors = <int>[
    0xFF5B5FC7, // indigo
    0xFFD83B01, // orange
    0xFF107C10, // green
    0xFFE3008C, // pink
    0xFF0078D4, // blue
    0xFFFFB900, // yellow
    0xFF00B7C3, // teal
    0xFFC239B3, // magenta
    0xFF8E8CD8, // lavender
    0xFFAF8B6B, // brown
    0xFF8764B8, // purple
    0xFF69797E, // slate
  ];

  /// Default color for a new list: the first palette color no existing list
  /// uses, or the least used one once every color is taken.
  static int nextDefault(Iterable<int> usedColors) {
    final counts = {for (final color in colors) color: 0};
    for (final color in usedColors) {
      final count = counts[color];
      if (count != null) counts[color] = count + 1;
    }
    var best = colors.first;
    for (final color in colors) {
      if (counts[color]! < counts[best]!) best = color;
    }
    return best;
  }
}
