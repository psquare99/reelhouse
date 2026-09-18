import 'package:flutter/material.dart';

import 'cinema_theme.dart';

/// 3-Layer Token Palette for REELHOUSE: Personal Digital Cinema.
///
/// Follows REELHOUSE UI & Theme System Specification:
/// - Layer 1 (Palette): Raw hex definitions.
/// - Layer 2 (Theme): Screening Room (Dark) and Gallery Linen (Light) mappings.
/// - Layer 3 (Semantic Roles): Resolved dynamically via `CinemaTheme.of(context)`
///   or `CinemaColors.of*(context)`.
///
/// **Rule: No UI/presentation code may use raw `Color(0xFF...)` or `Colors.*`.**
/// All UI surfaces must resolve through dynamic semantic roles.
class CinemaColors {
  CinemaColors._();

  // ==========================================
  // Layer 1 — Raw Palette Definitions
  // ==========================================

  // --- Screening Room (Dark) Palette ---
  static const Color darkBackground = Color(0xFF0B0C0E);
  static const Color darkSurface1 = Color(0xFF16181C);
  static const Color darkSurface2 = Color(0xFF1E2126);
  static const Color darkBorder = Color(0xFF2A2D33);
  static const Color darkBorderStrong = Color(0xFF3A3E45);
  static const Color darkTextPrimary = Color(0xFFF2F0EC);
  static const Color darkTextSecondary = Color(0xFFA8A6A0);
  static const Color darkTextMuted = Color(0xFF6E6C68);
  static const Color darkAccent = Color(0xFFE2703A);
  static const Color darkOnAccent = Color(0xFF1A0D06);
  static const Color darkStateAvailable = Color(0xFFE2703A);
  static const Color darkStateOffline = Color(0xFF5DCAA5);
  static const Color darkStateUnavailable = Color(0xFF6E6C68);
  static const Color darkStateProgress = Color(0xFFEF9F27);

  // --- Gallery Linen (Light) Palette ---
  static const Color lightBackground = Color(0xFFF3EEE3);
  static const Color lightSurface1 = Color(0xFFFBF9F4);
  static const Color lightSurface2 = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE1DAC9);
  static const Color lightBorderStrong = Color(0xFFC9BFA6);
  static const Color lightTextPrimary = Color(0xFF241F19);
  static const Color lightTextSecondary = Color(0xFF5C564C);
  static const Color lightTextMuted = Color(0xFF8B8579);
  static const Color lightAccent = Color(0xFFC24E28);
  static const Color lightOnAccent = Color(0xFFFFFFFF);
  static const Color lightStateAvailable = Color(0xFFC24E28);
  static const Color lightStateOffline = Color(0xFF0F6E56);
  static const Color lightStateUnavailable = Color(0xFF8B8579);
  static const Color lightStateProgress = Color(0xFF854F0B);

  // --- Static Aliases for backward compatibility in non-presentation code ---
  static const Color terracotta = darkAccent;
  static const Color terracottaLight = Color(0xFFF29E85);
  static const Color terracottaDark = lightAccent;
  static const Color terracottaSubtle = Color(0x24E2703A);
  static const Color amber = darkAccent;
  static const Color amberLight = terracottaLight;
  static const Color amberDark = lightAccent;
  static const Color amberSubtle = terracottaSubtle;
  static const Color copper = darkAccent;
  static const Color sienna = lightAccent;

  static const Color darkCanvas = darkBackground;
  static const Color darkSurface = darkSurface1;
  static const Color darkSurfaceElevated = darkSurface2;
  static const Color darkCard = darkSurface1;
  static const Color darkCardHover = darkSurface2;
  static const Color darkInteractive = darkSurface2;
  static const Color darkBorderSubtle = darkBorder;

  static const Color lightCanvas = lightBackground;
  static const Color lightSurface = lightSurface1;
  static const Color lightSurfaceElevated = lightSurface2;
  static const Color lightCard = lightSurface2;
  static const Color lightCardHover = lightSurface1;
  static const Color lightInteractive = lightSurface1;
  static const Color lightBorderSubtle = lightBorder;
  static const Color lightDivider = lightBorder;

  static const Color canvas = darkBackground;
  static const Color surface = darkSurface1;
  static const Color surfaceElevated = darkSurface2;
  static const Color card = darkSurface1;
  static const Color cardHover = darkSurface2;
  static const Color interactive = darkSurface2;
  static const Color border = darkBorder;
  static const Color borderSubtle = darkBorder;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;

  // Status Indicators (aliases)
  static const Color statusAvailable = darkStateAvailable;
  static const Color statusOfflineAvailable = darkStateOffline;
  static const Color statusUnavailable = darkStateUnavailable;
  static const Color statusWarning = darkStateProgress;
  static const Color statusError = Color(0xFFDC2626);

  // ==========================================
  // Layer 3 — Semantic Dynamic Resolvers
  // ==========================================

  /// Page background canvas.
  static Color ofBackground(BuildContext context) =>
      CinemaTheme.of(context).background;

  /// Primary card and poster tile surface.
  static Color ofSurface1(BuildContext context) =>
      CinemaTheme.of(context).surface1;

  /// Elevated inputs, modals, elevated panels, and dialogs.
  static Color ofSurface2(BuildContext context) =>
      CinemaTheme.of(context).surface2;

  /// Structural hairline dividers and card outlines.
  static Color ofBorder(BuildContext context) => CinemaTheme.of(context).border;

  /// Emphasized border and input focus outlines.
  static Color ofBorderStrong(BuildContext context) =>
      CinemaTheme.of(context).borderStrong;

  /// Primary titles, headings, and high-contrast labels.
  static Color ofTextPrimary(BuildContext context) =>
      CinemaTheme.of(context).textPrimary;

  /// Supporting text, field values, and secondary metadata.
  static Color ofTextSecondary(BuildContext context) =>
      CinemaTheme.of(context).textSecondary;

  /// Placeholders, timestamps, and subdued hints.
  static Color ofTextMuted(BuildContext context) =>
      CinemaTheme.of(context).textMuted;

  /// Brand accent, active navigation, and primary actions.
  static Color ofAccent(BuildContext context) => CinemaTheme.of(context).accent;

  /// Text and icons rendered atop an accent-filled surface.
  static Color ofOnAccent(BuildContext context) =>
      CinemaTheme.of(context).onAccent;

  /// Ready / Play / Available on disk state token.
  static Color ofStateAvailable(BuildContext context) =>
      CinemaTheme.of(context).stateAvailable;

  /// Play offline / Available offline state token.
  static Color ofStateOffline(BuildContext context) =>
      CinemaTheme.of(context).stateOffline;

  /// Connect disk / Storage unavailable state token.
  static Color ofStateUnavailable(BuildContext context) =>
      CinemaTheme.of(context).stateUnavailable;

  /// In-progress / Downloading state token.
  static Color ofStateProgress(BuildContext context) =>
      CinemaTheme.of(context).stateProgress;

  /// Accent with ~14% opacity for active pills and subtle highlights.
  static Color ofAccentSubtle(BuildContext context) =>
      CinemaTheme.of(context).accent.withValues(alpha: 0.14);

  // --- Backward-Compatible Aliases ---
  static Color ofCanvas(BuildContext context) => ofBackground(context);
  static Color ofSurface(BuildContext context) => ofSurface1(context);
  static Color ofSurfaceElevated(BuildContext context) => ofSurface2(context);
  static Color ofCard(BuildContext context) => ofSurface1(context);
  static Color ofCardHover(BuildContext context) => ofSurface2(context);
  static Color ofBorderSubtle(BuildContext context) => ofBorder(context);
}
