import 'package:flutter/material.dart';

import 'cinema_colors.dart';

/// Cinematic theme for REELHOUSE.
class CinemaTheme {
  CinemaTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CinemaColors.canvas,
      colorScheme: const ColorScheme.dark(
        primary: CinemaColors.amber,
        onPrimary: CinemaColors.canvas,
        primaryContainer: CinemaColors.amberDark,
        surface: CinemaColors.surface,
        onSurface: CinemaColors.textPrimary,
        surfaceContainerLow: CinemaColors.surface,
        surfaceContainer: CinemaColors.surfaceElevated,
        surfaceContainerHighest: CinemaColors.card,
        outline: CinemaColors.border,
        outlineVariant: CinemaColors.borderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CinemaColors.canvas,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: CinemaColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: CinemaColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: CinemaColors.borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CinemaColors.amber,
          foregroundColor: CinemaColors.canvas,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CinemaColors.textPrimary,
          side: const BorderSide(color: CinemaColors.border, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: CinemaColors.surface,
        selectedIconTheme: IconThemeData(color: CinemaColors.amber, size: 24),
        unselectedIconTheme: IconThemeData(
          color: CinemaColors.textSecondary,
          size: 22,
        ),
        selectedLabelTextStyle: TextStyle(
          color: CinemaColors.amber,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: CinemaColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CinemaColors.surface,
        indicatorColor: CinemaColors.amberSubtle,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: CinemaColors.amber);
          }
          return const IconThemeData(color: CinemaColors.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: CinemaColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: CinemaColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: CinemaColors.borderSubtle,
        thickness: 1,
      ),
    );
  }
}
