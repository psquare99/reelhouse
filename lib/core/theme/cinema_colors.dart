import 'package:flutter/material.dart';

/// Palette for REELHOUSE: Personal Digital Cinema.
///
/// Designed with an authentic, warm, refined cinema visual identity:
/// - Primary Accent: Warm Terracotta / Vintage Copper / Cinema Sienna
/// - Dark Mode (The Screening Room): Deep obsidian charcoal canvas, elevated surfaces, and warm ivory typography
/// - Light Mode (The Exhibition / Gallery Linen): Warm gallery linen canvas, crisp white card surfaces, visible structural borders, and deep slate typography
class CinemaColors {
  CinemaColors._();

  // --- Cinema Terracotta / Vintage Copper / Sienna Accents ---
  static const Color terracotta = Color(0xFFE07A5F);
  static const Color terracottaLight = Color(0xFFF29E85);
  static const Color terracottaDark = Color(0xFFB84A28);
  static const Color terracottaSubtle = Color(0x1FE07A5F);
  static const Color terracottaGlow = Color(0x33E07A5F);
  static const Color copper = Color(0xFFD96B43);
  static const Color sienna = Color(0xFFB84A28);

  // Accent aliases for existing codebase references
  static const Color amber = terracotta;
  static const Color amberLight = terracottaLight;
  static const Color amberDark = terracottaDark;
  static const Color amberSubtle = terracottaSubtle;

  // --- Dark Mode: The Screening Room ---
  static const Color darkCanvas = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF17191E);
  static const Color darkSurfaceElevated = Color(0xFF1E2127);
  static const Color darkCard = Color(0xFF1A1D23);
  static const Color darkCardHover = Color(0xFF22262E);
  static const Color darkInteractive = Color(0xFF2A2F38);
  static const Color darkBorder = Color(0xFF333842);
  static const Color darkBorderSubtle = Color(0xFF242830);
  static const Color darkTextPrimary = Color(0xFFF2EFE9);
  static const Color darkTextSecondary = Color(0xFFA0A5AD);
  static const Color darkTextMuted = Color(0xFF6E747F);

  // --- Light Mode: The Exhibition / Gallery Linen ---
  static const Color lightCanvas = Color(0xFFF7F5F0);
  static const Color lightSurface = Color(0xFFECE6DC);
  static const Color lightSurfaceElevated = Color(0xFFE3DCCF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF0EBE1);
  static const Color lightInteractive = Color(0xFFE5DEC0);
  static const Color lightBorder = Color(0xFFB8ADA0);
  static const Color lightBorderSubtle = Color(0xFFD2C7B8);
  static const Color lightDivider = Color(0xFFD0C5B5);
  static const Color lightTextPrimary = Color(0xFF141619);
  static const Color lightTextSecondary = Color(0xFF3F454E);
  static const Color lightTextMuted = Color(0xFF606672);

  // --- Default Static Aliases ---
  static const Color canvas = darkCanvas;
  static const Color surface = darkSurface;
  static const Color surfaceElevated = darkSurfaceElevated;
  static const Color card = darkCard;
  static const Color cardHover = darkCardHover;
  static const Color interactive = darkInteractive;
  static const Color border = darkBorder;
  static const Color borderSubtle = darkBorderSubtle;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;

  // --- Status Indicators ---
  static const Color statusAvailable = Color(0xFF10B981);
  static const Color statusOfflineAvailable = Color(0xFF38BDF8);
  static const Color statusUnavailable = Color(0xFF6E747F);
  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusError = Color(0xFFDC2626);

  // --- Theme-Aware Dynamic Resolvers ---
  static Color ofCanvas(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightCanvas
      : darkCanvas;

  static Color ofSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightSurface
      : darkSurface;

  static Color ofSurfaceElevated(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightSurfaceElevated
      : darkSurfaceElevated;

  static Color ofCard(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? lightCard : darkCard;

  static Color ofCardHover(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightCardHover
      : darkCardHover;

  static Color ofBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightBorder
      : darkBorder;

  static Color ofBorderSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightBorderSubtle
      : darkBorderSubtle;

  static Color ofTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightTextPrimary
      : darkTextPrimary;

  static Color ofTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightTextSecondary
      : darkTextSecondary;

  static Color ofTextMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? lightTextMuted
      : darkTextMuted;

  static Color ofAccent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? terracottaDark
      : terracotta;

  static Color ofAccentSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? const Color(0x24B84A28)
      : terracottaSubtle;
}
