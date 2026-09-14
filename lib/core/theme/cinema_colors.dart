import 'package:flutter/material.dart';

/// Palette for REELHOUSE: Personal Digital Cinema.
///
/// Designed to evoke a private screening room: deep obsidian background,
/// subtle charcoal elevations, and warm amber projection-lamp accents.
class CinemaColors {
  CinemaColors._();

  // Canvas & Surfaces (Obsidian, Warm Charcoal, Elevation layers)
  static const Color canvas = Color(0xFF0D0E11);
  static const Color surface = Color(0xFF15171C);
  static const Color surfaceElevated = Color(0xFF1D2026);
  static const Color card = Color(0xFF1A1C22);
  static const Color cardHover = Color(0xFF23262E);
  static const Color interactive = Color(0xFF2B2F38);
  static const Color border = Color(0xFF272A32);
  static const Color borderSubtle = Color(0xFF1E2128);

  // Muted Brass & Warm Gold Accents (Cinematic highlight, restrained)
  static const Color amber = Color(0xFFC5A059);
  static const Color amberLight = Color(0xFFD4B36D);
  static const Color amberDark = Color(0xFFA8843E);
  static const Color amberSubtle = Color(0x1FC5A059);

  // Typography (Restrained Ivory & Softer Secondary Text)
  static const Color textPrimary = Color(0xFFEAE6DF);
  static const Color textSecondary = Color(0xFF9CA1A6);
  static const Color textMuted = Color(0xFF63686E);

  // Status Indicators (Understated)
  static const Color statusAvailable = Color(0xFF10B981);
  static const Color statusOfflineAvailable = Color(0xFF38BDF8);
  static const Color statusUnavailable = Color(0xFF63686E);
  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusError = Color(0xFFDC2626);
}
