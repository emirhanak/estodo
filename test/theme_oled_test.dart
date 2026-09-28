import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estodo/app/theme/app_theme.dart';

void main() {
  test('AppTheme.oled generates pure black scaffold and surface', () {
    final theme = AppTheme.oled();

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(theme.colorScheme.surface, const Color(0xFF000000));
    expect(theme.colorScheme.surfaceDim, const Color(0xFF000000));
    expect(theme.cardTheme.color, const Color(0xFF0C0C0C));
    expect(theme.bottomSheetTheme.backgroundColor, const Color(0xFF080808));
    expect(theme.navigationRailTheme.backgroundColor, const Color(0xFF000000));
    expect(theme.navigationBarTheme.backgroundColor, const Color(0xFF000000));
  });

  test('AppTheme.oled respects custom accent seed', () {
    const customAccent = Color(0xFF107C10);
    final theme = AppTheme.oled(accent: customAccent);

    expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(theme.colorScheme.surface, const Color(0xFF000000));
    expect(theme.brightness, Brightness.dark);
  });
}
