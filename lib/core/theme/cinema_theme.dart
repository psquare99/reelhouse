import 'package:flutter/material.dart';

import 'cinema_colors.dart';

/// Cinematic theme system for REELHOUSE: Personal Digital Cinema.
///
/// Provides both Dark (The Screening Room) and Light (The Exhibition / Gallery Linen)
/// themes sharing the signature Warm Terracotta / Cinema Sienna accent with strong,
/// intentional visual contrast and clear structural hierarchy.
class CinemaTheme {
  CinemaTheme._();

  /// Dark Cinema Theme: The Screening Room.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CinemaColors.darkCanvas,
      colorScheme: const ColorScheme.dark(
        primary: CinemaColors.terracotta,
        onPrimary: CinemaColors.darkCanvas,
        primaryContainer: CinemaColors.terracottaDark,
        onPrimaryContainer: CinemaColors.darkTextPrimary,
        surface: CinemaColors.darkSurface,
        onSurface: CinemaColors.darkTextPrimary,
        surfaceContainerLow: CinemaColors.darkCanvas,
        surfaceContainer: CinemaColors.darkSurfaceElevated,
        surfaceContainerHighest: CinemaColors.darkCard,
        outline: CinemaColors.darkBorder,
        outlineVariant: CinemaColors.darkBorderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CinemaColors.darkCanvas,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: CinemaColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: CinemaColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: CinemaColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: CinemaColors.darkBorderSubtle, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: CinemaColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CinemaColors.darkBorderSubtle),
        ),
        titleTextStyle: const TextStyle(
          color: CinemaColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CinemaColors.darkCard,
        modalBackgroundColor: CinemaColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CinemaColors.terracotta,
          foregroundColor: CinemaColors.darkCanvas,
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
          foregroundColor: CinemaColors.darkTextPrimary,
          side: const BorderSide(color: CinemaColors.darkBorder, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CinemaColors.terracotta,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: CinemaColors.darkSurface,
        selectedIconTheme: IconThemeData(
          color: CinemaColors.terracotta,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: CinemaColors.darkTextSecondary,
          size: 22,
        ),
        selectedLabelTextStyle: TextStyle(
          color: CinemaColors.terracotta,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: CinemaColors.darkTextMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CinemaColors.darkSurface,
        indicatorColor: CinemaColors.terracottaSubtle,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: CinemaColors.terracotta);
          }
          return const IconThemeData(color: CinemaColors.darkTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: CinemaColors.terracotta,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: CinemaColors.darkTextMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CinemaColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CinemaColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CinemaColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: CinemaColors.terracotta,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(color: CinemaColors.darkTextSecondary),
        hintStyle: const TextStyle(color: CinemaColors.darkTextMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CinemaColors.darkSurface,
        selectedColor: CinemaColors.terracotta,
        labelStyle: const TextStyle(
          color: CinemaColors.darkTextSecondary,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          color: CinemaColors.darkCanvas,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: CinemaColors.darkBorderSubtle),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: CinemaColors.darkBorderSubtle,
        thickness: 1,
      ),
    );
  }

  /// Light Cinema Theme: The Exhibition / Gallery Linen.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: CinemaColors.lightCanvas,
      colorScheme: const ColorScheme.light(
        primary: CinemaColors.terracottaDark,
        onPrimary: Colors.white,
        primaryContainer: Color(0x24B84A28),
        onPrimaryContainer: CinemaColors.terracottaDark,
        surface: CinemaColors.lightSurface,
        onSurface: CinemaColors.lightTextPrimary,
        surfaceContainerLow: CinemaColors.lightCanvas,
        surfaceContainer: CinemaColors.lightSurface,
        surfaceContainerHighest: CinemaColors.lightCard,
        outline: CinemaColors.lightBorder,
        outlineVariant: CinemaColors.lightBorderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CinemaColors.lightCanvas,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: CinemaColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: CinemaColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: CinemaColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: CinemaColors.lightBorderSubtle,
            width: 1.2,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: CinemaColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: CinemaColors.lightBorderSubtle,
            width: 1.2,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: CinemaColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CinemaColors.lightCard,
        modalBackgroundColor: CinemaColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CinemaColors.terracottaDark,
          foregroundColor: Colors.white,
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
          foregroundColor: CinemaColors.lightTextPrimary,
          side: const BorderSide(color: CinemaColors.lightBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CinemaColors.terracottaDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: CinemaColors.lightSurface,
        selectedIconTheme: IconThemeData(
          color: CinemaColors.terracottaDark,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: CinemaColors.lightTextSecondary,
          size: 22,
        ),
        selectedLabelTextStyle: TextStyle(
          color: CinemaColors.terracottaDark,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: CinemaColors.lightTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CinemaColors.lightSurface,
        indicatorColor: const Color(0x24B84A28),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: CinemaColors.terracottaDark);
          }
          return const IconThemeData(color: CinemaColors.lightTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: CinemaColors.terracottaDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: CinemaColors.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: CinemaColors.lightBorder,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: CinemaColors.lightBorder,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: CinemaColors.terracottaDark,
            width: 1.8,
          ),
        ),
        labelStyle: const TextStyle(
          color: CinemaColors.lightTextSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: CinemaColors.lightTextMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CinemaColors.lightSurface,
        selectedColor: CinemaColors.terracottaDark,
        labelStyle: const TextStyle(
          color: CinemaColors.lightTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: CinemaColors.lightBorderSubtle,
            width: 1.0,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: CinemaColors.lightDivider,
        thickness: 1,
      ),
    );
  }
}
