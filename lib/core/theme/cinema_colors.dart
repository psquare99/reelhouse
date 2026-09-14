import 'package:flutter/material.dart';

/// Palette for REELHOUSE: Personal Digital Cinema.
///
/// Designed to evoke a private screening room: deep obsidian background,
/// subtle charcoal elevations, and warm amber projection-lamp accents.
class CinemaColors {
  CinemaColors._();

  // Canvas & Backgrounds
  static const Color canvas = Color(0xFF0B0C0E);
  static const Color surface = Color(0xFF121418);
  static const Color card = Color(0xFF1A1D24);
  static const Color cardHover = Color(0xFF242831);
  static const Color border = Color(0xFF282D37);
  static const Color borderSubtle = Color(0xFF1F232B);

  // Warm Amber Accents (Cinema Projection)
  static const Color amber = Color(0xFFE5A93C);
  static const Color amberLight = Color(0xFFF5B942);
  static const Color amberDark = Color(0xFFC48A2C);
  static const Color amberSubtle = Color(0x26E5A93C);

  // Typography
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Status Indicators
  static const Color statusAvailable = Color(0xFF10B981);
  static const Color statusOfflineAvailable = Color(0xFF38BDF8);
  static const Color statusUnavailable = Color(0xFF6B7280);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusError = Color(0xFFEF4444);
}
