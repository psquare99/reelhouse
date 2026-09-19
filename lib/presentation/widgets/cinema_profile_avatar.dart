import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';

/// Computes 1-2 character uppercase initials from a user's display name.
String getProfileInitials(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) return 'V';
  final parts = trimmed
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'V';
  if (parts.length == 1) {
    return parts[0][0].toUpperCase();
  }
  return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
}

/// A cinema-styled circular profile avatar supporting local image files and
/// graceful fallback to initial-based generated avatars.
class CinemaProfileAvatar extends StatelessWidget {
  final double size;
  final String displayName;
  final String? profilePicturePath;
  final VoidCallback? onTap;
  final double? fontSize;
  final bool showBorder;

  const CinemaProfileAvatar({
    super.key,
    required this.size,
    required this.displayName,
    this.profilePicturePath,
    this.onTap,
    this.fontSize,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);
    final calculatedFontSize = fontSize ?? (size * 0.40).clamp(10.0, 36.0);
    final initials = getProfileInitials(displayName);

    Widget avatarContent;

    if (profilePicturePath != null && profilePicturePath!.trim().isNotEmpty) {
      avatarContent = ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.file(
            File(profilePicturePath!.trim()),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildInitialsFallback(theme, initials, calculatedFontSize),
          ),
        ),
      );
    } else {
      avatarContent = _buildInitialsFallback(
        theme,
        initials,
        calculatedFontSize,
      );
    }

    if (showBorder) {
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.accent.withValues(alpha: 0.35),
            width: size >= 60 ? 2.0 : 1.2,
          ),
        ),
        child: avatarContent,
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: avatarContent,
        ),
      );
    }

    return avatarContent;
  }

  Widget _buildInitialsFallback(
    CinemaThemeData theme,
    String initials,
    double calculatedFontSize,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.accent.withValues(alpha: 0.15),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: theme.accent,
          fontSize: calculatedFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
