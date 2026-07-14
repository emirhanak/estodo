// Kept explicit for Flutter versions where Material no longer re-exports it.
// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  const AppTheme._();

  static const seed = Color(0xFF8E8CD8);
  static const lightSurface = Color(0xFFFAF9F8);
  static const darkSurface = Color(0xFF201F1E);

  static ThemeData light({Color? accent}) {
    return _base(
      ColorScheme.fromSeed(
        seedColor: accent ?? seed,
        brightness: Brightness.light,
        surface: lightSurface,
      ),
      Brightness.light,
    );
  }

  static ThemeData dark({Color? accent}) {
    return _base(
      ColorScheme.fromSeed(
        seedColor: accent ?? seed,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      Brightness.dark,
    );
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.45),
        selectedColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 6,
        shape: const CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displayMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4),
        headlineLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.1),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.1),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontWeight: FontWeight.w500, height: 1.35),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400, height: 1.4),
        bodySmall: TextStyle(fontWeight: FontWeight.w400, height: 1.35),
        labelLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
    );
  }
}

class ListPalette {
  const ListPalette._();

  static const colors = <int>[
    0xFF8E8CD8, // signature purple
    0xFF5B5FC7, // indigo
    0xFF0078D4, // azure
    0xFF00B7C3, // teal
    0xFF107C10, // green
    0xFFFFB900, // gold
    0xFFD83B01, // orange
    0xFFE3008C, // pink
    0xFFC239B3, // magenta
    0xFF8764B8, // mauve
    0xFFAF8B6B, // taupe
    0xFF69797E, // graphite
  ];

  static Color resolve(int value) => Color(value);
}
