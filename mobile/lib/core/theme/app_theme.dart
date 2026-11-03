import 'package:flutter/material.dart';

/// High-contrast light and dark themes with 56 dp minimum touch targets (FR-5.2).
class AppTheme {
  static const _seed = Color(0xFF2E7D32);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness, contrastLevel: 0.5);
    // Cards sit one step above the page so they read as cards in both modes.
    final page = dark ? scheme.surface : scheme.surfaceContainerLow;
    final card = dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    const minSize = Size(64, 56);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness);
    return base.copyWith(
      scaffoldBackgroundColor: page,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: page,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: scheme.shadow.withValues(alpha: .3),
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? .5 : .7)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: minSize, shape: shape, textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: minSize, shape: shape, textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(minimumSize: const Size(48, 52), textStyle: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: .6)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 16),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: card,
        indicatorColor: scheme.primaryContainer,
        selectedLabelTextStyle: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: .6), space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
    );
  }
}

/// Status colours Material does not have (waiting / warning, success), tuned for light and dark.
extension StatusColors on ColorScheme {
  bool get _dark => brightness == Brightness.dark;

  /// Solid amber with readable text on it (badges over photos).
  Color get warning => _dark ? const Color(0xFFFFC94D) : const Color(0xFF8A5A00);
  Color get onWarning => _dark ? const Color(0xFF3D2A00) : Colors.white;

  /// Soft amber for highlighted cards and pills.
  Color get warningContainer => _dark ? const Color(0xFF3F3000) : const Color(0xFFFFEDB8);
  Color get onWarningContainer => _dark ? const Color(0xFFFFE08A) : const Color(0xFF5C3D00);
}
