import 'package:flutter/material.dart';

import 'cinema_colors.dart';

/// Semantic token data extension for REELHOUSE themes.
///
/// Contains all 14 Layer-3 semantic tokens defined in REELHOUSE UI & Theme System:
/// - `background`, `surface1`, `surface2`
/// - `border`, `borderStrong`
/// - `textPrimary`, `textSecondary`, `textMuted`
/// - `accent`, `onAccent`
/// - `stateAvailable`, `stateOffline`, `stateUnavailable`, `stateProgress`
class CinemaThemeData extends ThemeExtension<CinemaThemeData> {
  final Color background;
  final Color surface1;
  final Color surface2;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color stateAvailable;
  final Color stateOffline;
  final Color stateUnavailable;
  final Color stateProgress;

  const CinemaThemeData({
    required this.background,
    required this.surface1,
    required this.surface2,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.stateAvailable,
    required this.stateOffline,
    required this.stateUnavailable,
    required this.stateProgress,
  });

  /// Screening Room (Dark Mode) semantic tokens.
  static const CinemaThemeData screeningRoom = CinemaThemeData(
    background: CinemaColors.darkBackground,
    surface1: CinemaColors.darkSurface1,
    surface2: CinemaColors.darkSurface2,
    border: CinemaColors.darkBorder,
    borderStrong: CinemaColors.darkBorderStrong,
    textPrimary: CinemaColors.darkTextPrimary,
    textSecondary: CinemaColors.darkTextSecondary,
    textMuted: CinemaColors.darkTextMuted,
    accent: CinemaColors.darkAccent,
    onAccent: CinemaColors.darkOnAccent,
    stateAvailable: CinemaColors.darkStateAvailable,
    stateOffline: CinemaColors.darkStateOffline,
    stateUnavailable: CinemaColors.darkStateUnavailable,
    stateProgress: CinemaColors.darkStateProgress,
  );

  /// Gallery Linen (Light Mode) semantic tokens.
  static const CinemaThemeData galleryLinen = CinemaThemeData(
    background: CinemaColors.lightBackground,
    surface1: CinemaColors.lightSurface1,
    surface2: CinemaColors.lightSurface2,
    border: CinemaColors.lightBorder,
    borderStrong: CinemaColors.lightBorderStrong,
    textPrimary: CinemaColors.lightTextPrimary,
    textSecondary: CinemaColors.lightTextSecondary,
    textMuted: CinemaColors.lightTextMuted,
    accent: CinemaColors.lightAccent,
    onAccent: CinemaColors.lightOnAccent,
    stateAvailable: CinemaColors.lightStateAvailable,
    stateOffline: CinemaColors.lightStateOffline,
    stateUnavailable: CinemaColors.lightStateUnavailable,
    stateProgress: CinemaColors.lightStateProgress,
  );

  /// Convenience aliases for backward compatibility and semantic clarity.
  Color get surface => surface1;
  Color get borderSubtle => border;
  Color get statusAvailable => stateAvailable;
  Color get statusOffline => stateOffline;
  Color get statusMissing => stateUnavailable;
  Color get statusUnavailable => stateUnavailable;
  Color get statusProgress => stateProgress;
  Color get accentMuted => accent.withValues(alpha: 0.15);
  Color get warning => accent;
  Color get warningSubtle => accent.withValues(alpha: 0.15);

  @override
  CinemaThemeData copyWith({
    Color? background,
    Color? surface1,
    Color? surface2,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    Color? stateAvailable,
    Color? stateOffline,
    Color? stateUnavailable,
    Color? stateProgress,
  }) {
    return CinemaThemeData(
      background: background ?? this.background,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      stateAvailable: stateAvailable ?? this.stateAvailable,
      stateOffline: stateOffline ?? this.stateOffline,
      stateUnavailable: stateUnavailable ?? this.stateUnavailable,
      stateProgress: stateProgress ?? this.stateProgress,
    );
  }

  @override
  CinemaThemeData lerp(ThemeExtension<CinemaThemeData>? other, double t) {
    if (other is! CinemaThemeData) return this;
    return CinemaThemeData(
      background: Color.lerp(background, other.background, t) ?? background,
      surface1: Color.lerp(surface1, other.surface1, t) ?? surface1,
      surface2: Color.lerp(surface2, other.surface2, t) ?? surface2,
      border: Color.lerp(border, other.border, t) ?? border,
      borderStrong:
          Color.lerp(borderStrong, other.borderStrong, t) ?? borderStrong,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      onAccent: Color.lerp(onAccent, other.onAccent, t) ?? onAccent,
      stateAvailable:
          Color.lerp(stateAvailable, other.stateAvailable, t) ?? stateAvailable,
      stateOffline:
          Color.lerp(stateOffline, other.stateOffline, t) ?? stateOffline,
      stateUnavailable:
          Color.lerp(stateUnavailable, other.stateUnavailable, t) ??
          stateUnavailable,
      stateProgress:
          Color.lerp(stateProgress, other.stateProgress, t) ?? stateProgress,
    );
  }
}

/// Cinematic theme system for REELHOUSE: Personal Digital Cinema.
///
/// Implements token-based ThemeData for both Screening Room (Dark) and Gallery Linen (Light)
/// with typography, component shapes, flat elevations, and dynamic theme extensions.
class CinemaTheme {
  CinemaTheme._();

  /// Resolves the current [CinemaThemeData] semantic tokens from [context].
  static CinemaThemeData of(BuildContext context) {
    final ext = Theme.of(context).extension<CinemaThemeData>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.light
        ? CinemaThemeData.galleryLinen
        : CinemaThemeData.screeningRoom;
  }

  /// Display serif style for movie/show titles on detail pages and Home hero.
  static TextStyle displaySerif(
    BuildContext context, {
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w500,
    double? letterSpacing,
  }) {
    final tokens = of(context);
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing ?? 0.5,
      color: tokens.textPrimary,
      fontFamily: 'serif',
    );
  }

  /// Tracked uppercase eyebrow label style in UI sans.
  static TextStyle eyebrow(
    BuildContext context, {
    double fontSize = 11,
    Color? color,
  }) {
    final tokens = of(context);
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.8,
      color: color ?? tokens.accent,
    );
  }

  /// Alias for [eyebrow].
  static TextStyle eyebrowStyle(
    BuildContext context, {
    double fontSize = 11,
    Color? color,
  }) => eyebrow(context, fontSize: fontSize, color: color);

  /// Section heading style in UI sans.
  static TextStyle heading(
    BuildContext context, {
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    final tokens = of(context);
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.3,
      color: tokens.textPrimary,
    );
  }

  /// Body style in UI sans.
  static TextStyle body(
    BuildContext context, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    final tokens = of(context);
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? tokens.textPrimary,
    );
  }

  /// Muted caption style in UI sans.
  static TextStyle caption(
    BuildContext context, {
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    final tokens = of(context);
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: tokens.textMuted,
    );
  }

  /// Dark Cinema Theme: The Screening Room.
  static ThemeData get darkTheme {
    final tokens = CinemaThemeData.screeningRoom;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      cardColor: tokens.surface1,
      dividerColor: tokens.border,
      extensions: [tokens],
      colorScheme: ColorScheme.dark(
        primary: tokens.accent,
        onPrimary: tokens.onAccent,
        primaryContainer: tokens.surface2,
        onPrimaryContainer: tokens.textPrimary,
        surface: tokens.surface1,
        onSurface: tokens.textPrimary,
        surfaceContainerLow: tokens.background,
        surfaceContainer: tokens.surface1,
        surfaceContainerHigh: tokens.surface2,
        surfaceContainerHighest: tokens.surface2,
        outline: tokens.border,
        outlineVariant: tokens.borderStrong,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: tokens.textPrimary),
        titleTextStyle: TextStyle(
          color: tokens.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface1,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.borderStrong, width: 1),
        ),
        titleTextStyle: TextStyle(
          color: tokens.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface2,
        modalBackgroundColor: tokens.surface2,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.onAccent,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.borderStrong, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.background,
        elevation: 0,
        selectedIconTheme: IconThemeData(color: tokens.accent, size: 24),
        unselectedIconTheme: IconThemeData(
          color: tokens.textSecondary,
          size: 22,
        ),
        selectedLabelTextStyle: TextStyle(
          color: tokens.accent,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: tokens.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.background,
        elevation: 0,
        indicatorColor: tokens.accent.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: tokens.accent);
          }
          return IconThemeData(color: tokens.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: tokens.accent,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            );
          }
          return TextStyle(
            color: tokens.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.borderStrong, width: 1.5),
        ),
        labelStyle: TextStyle(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: TextStyle(
          color: tokens.textMuted,
          fontWeight: FontWeight.w400,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surface1,
        selectedColor: tokens.accent,
        labelStyle: TextStyle(color: tokens.textSecondary, fontSize: 13),
        secondaryLabelStyle: TextStyle(
          color: tokens.onAccent,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tokens.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Light Cinema Theme: The Exhibition / Gallery Linen.
  static ThemeData get lightTheme {
    final tokens = CinemaThemeData.galleryLinen;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      cardColor: tokens.surface1,
      dividerColor: tokens.border,
      extensions: [tokens],
      colorScheme: ColorScheme.light(
        primary: tokens.accent,
        onPrimary: tokens.onAccent,
        primaryContainer: tokens.surface2,
        onPrimaryContainer: tokens.textPrimary,
        surface: tokens.surface1,
        onSurface: tokens.textPrimary,
        surfaceContainerLow: tokens.background,
        surfaceContainer: tokens.surface1,
        surfaceContainerHigh: tokens.surface2,
        surfaceContainerHighest: tokens.surface2,
        outline: tokens.border,
        outlineVariant: tokens.borderStrong,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: tokens.textPrimary),
        titleTextStyle: TextStyle(
          color: tokens.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface1,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.borderStrong, width: 1),
        ),
        titleTextStyle: TextStyle(
          color: tokens.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface2,
        modalBackgroundColor: tokens.surface2,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.onAccent,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.borderStrong, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.background,
        elevation: 0,
        selectedIconTheme: IconThemeData(color: tokens.accent, size: 24),
        unselectedIconTheme: IconThemeData(
          color: tokens.textSecondary,
          size: 22,
        ),
        selectedLabelTextStyle: TextStyle(
          color: tokens.accent,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: tokens.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.background,
        elevation: 0,
        indicatorColor: tokens.accent.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: tokens.accent);
          }
          return IconThemeData(color: tokens.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: tokens.accent,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            );
          }
          return TextStyle(
            color: tokens.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.borderStrong, width: 1.5),
        ),
        labelStyle: TextStyle(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: TextStyle(
          color: tokens.textMuted,
          fontWeight: FontWeight.w400,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surface1,
        selectedColor: tokens.accent,
        labelStyle: TextStyle(color: tokens.textSecondary, fontSize: 13),
        secondaryLabelStyle: TextStyle(
          color: tokens.onAccent,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tokens.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
